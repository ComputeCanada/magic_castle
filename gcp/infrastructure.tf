provider "google" {
  project = var.project
  region  = var.region
}

module "design" {
  source       = "../common/design"
  cluster_name = var.cluster_name
  domain       = var.domain
  instances    = var.instances
  volumes      = var.volumes
}

module "instance_config" {
  source           = "../common/instance_config"
  instances        = module.design.instances
  config_git_url   = var.config_git_url
  config_version   = var.config_version
  puppetserver_ip  = local.puppetserver_ip
  sudoer_username  = var.sudoer_username
  public_keys      = var.public_keys
  generate_ssh_key = var.generate_ssh_key
}

module "cluster_config" {
  source          = "../common/cluster_config"
  instances       = local.all_instances
  nb_users        = var.nb_users
  hieradata       = var.hieradata
  software_stack  = var.software_stack
  cloud_provider  = local.cloud_provider
  cloud_region    = local.cloud_region
  sudoer_username = var.sudoer_username
  public_keys     = var.public_keys
  guest_passwd    = var.guest_passwd
  domain_name     = module.design.domain_name
  cluster_name    = var.cluster_name
  volume_devices  = local.volume_devices
  tf_ssh_key      = module.instance_config.ssh_key
}

data "google_compute_zones" "available" {
  status = "UP"
}

resource "random_shuffle" "random_zone" {
  input        = data.google_compute_zones.available.names
  result_count = 1
}

locals {
  zone = (
    (var.zone != "" &&
      contains(data.google_compute_zones.available.names,
      var.zone)
      ?
      var.zone : random_shuffle.random_zone.result[0]
    )
  )
}

data "external" "machine_type" {
  for_each = module.design.instances
  program  = ["bash", "${path.module}/external/machine_type.sh"]
  query    = {
    machine_type = each.value.type
  }
}

locals {
  to_build_instances = {
    for key, values in module.design.instances: key => values
    if ! contains(values.tags, "draft") || contains(var.draft_exclusion, key)
   }
}

resource "google_compute_instance" "instances" {
  for_each = local.to_build_instances
  project  = var.project
  zone     = local.zone

  name         = format("%s-%s", var.cluster_name, each.key)
  machine_type = each.value.type
  tags         = each.value.tags

  boot_disk {
    initialize_params {
      image = lookup(each.value, "image", var.image)
      type  = lookup(each.value, "disk_type", "pd-ssd")
      size  =  lookup(each.value, "disk_size", 20)
    }
  }

  scheduling {
    # Instances with guest accelerators
    # and spot instances
    # do not support live migration.
    on_host_maintenance = (lookup(each.value, "gpu_count", 0) > 0) || contains(each.value["tags"], "spot") ? "TERMINATE" : "MIGRATE"

    # Spot instance specifics
    preemptible       = contains(each.value["tags"], "spot")
    automatic_restart = !contains(each.value["tags"], "spot")
  }

  guest_accelerator {
    type  = lookup(each.value, "gpu_type", "")
    count = lookup(each.value, "gpu_count", 0)
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.self_link
    network_ip = google_compute_address.nic[each.key].address
    access_config {
      nat_ip = contains(each.value.tags, "public") ? google_compute_address.public_ip[each.key].address : null
    }
  }

  metadata = {
    enable-oslogin     = "FALSE"
    user-data          = base64gzip(module.instance_config.user_data[each.key])
    user-data-encoding = "base64"
    VmDnsSetting       = "ZonalOnly"
  }

  metadata_startup_script = file("${path.module}/install_cloudinit.sh")

  lifecycle {
    ignore_changes = [
      attached_disk,
      boot_disk[0].initialize_params[0].image,
      metadata,
    ]
  }
}

resource "google_compute_disk" "volumes" {
  for_each = module.design.volumes
  name     = "${var.cluster_name}-${each.key}"
  type     = lookup(each.value, "type", "pd-standard")
  zone     = local.zone
  size     = each.value.size
}

resource "google_compute_attached_disk" "attachments" {
  for_each    = module.design.volumes
  disk        = google_compute_disk.volumes[each.key].self_link
  device_name = google_compute_disk.volumes[each.key].name
  mode        = "READ_WRITE"
  instance    = google_compute_instance.instances[each.value.instance].self_link
}

locals {
  volume_devices = {
    for ki, vi in var.volumes :
    ki => {
      for kj, vj in vi :
      kj => [for key, volume in module.design.volumes :
        "/dev/disk/by-id/google-${var.cluster_name}-${volume["instance"]}-${ki}-${kj}"
        if key == "${volume["instance"]}-${ki}-${kj}"
      ]
    }
  }
}

locals {
  all_instances = { for x, values in module.design.instances :
    x => {
      public_ip = contains(values["tags"], "public") ? google_compute_address.public_ip[x].address : ""
      local_ip  = google_compute_address.nic[x].address
      tags      = values["tags"]
      id        = ! contains(values["tags"], "draft") || contains(var.draft_exclusion, x) ? google_compute_instance.instances[x].id : ""
      hostkeys = {
        rsa = module.instance_config.rsa_hostkeys[x]
        ed25519 = module.instance_config.ed25519_hostkeys[x]
      }
      specs = {
        cpus = data.external.machine_type[x].result["vcpus"]
        ram  = data.external.machine_type[x].result["ram"]
        gpu  = try(data.external.machine_type[x].result["gpus"], lookup(values, "gpu_count", 0))
      }
    }
  }
}

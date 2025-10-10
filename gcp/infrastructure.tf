provider "google" {
  project = var.project
  region  = var.region
}

module "design" {
  source         = "../common/design"
  cluster_name   = var.cluster_name
  domain         = var.domain
  image          = var.image
  instances      = var.instances
  min_disk_size  = 20
  pool           = var.pool
  volumes        = var.volumes
  firewall_rules = var.firewall_rules
  bastion_tags   = var.bastion_tags
}

module "configuration" {
  source          = "../common/configuration"
  inventory       = local.inventory
  config_git_url  = var.config_git_url
  config_version  = var.config_version
  sudoer_username = var.sudoer_username
  public_keys     = var.public_keys
  domain_name     = module.design.domain_name
  bastion_tags    = module.design.bastion_tags
  cluster_name    = var.cluster_name
  guest_passwd    = var.guest_passwd
  nb_users        = var.nb_users
  software_stack  = var.software_stack
  cloud_provider  = local.cloud_provider
  cloud_region    = local.cloud_region
  skip_upgrade    = var.skip_upgrade
  puppetfile      = var.puppetfile
}

module "provision" {
  source        = "../common/provision"
  configuration = module.configuration
  hieradata     = var.hieradata
  hieradata_dir = var.hieradata_dir
  eyaml_key     = var.eyaml_key
  puppetfile    = var.puppetfile
  depends_on    = [google_compute_instance.instances]
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
  for_each = var.instances
  program  = ["bash", "${path.module}/external/machine_type.sh"]
  query = {
    machine_type = each.value.type
  }
}

resource "google_compute_instance" "instances" {
  for_each = module.design.instances_to_build
  project  = var.project
  zone     = local.zone

  name         = format("%s-%s", var.cluster_name, each.key)
  machine_type = each.value.type
  tags         = each.value.tags

  boot_disk {
    initialize_params {
      image = each.value.image
      type  = lookup(each.value, "disk_type", "pd-ssd")
      size  = each.value.disk_size
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
    user-data          = base64gzip(module.configuration.user_data[each.key])
    user-data-encoding = "base64"
    VmDnsSetting       = "ZonalOnly"
  }

  metadata_startup_script = file("${path.module}/install_cloudinit.sh")

  lifecycle {
    ignore_changes = [
      attached_disk,
      boot_disk[0].initialize_params[0].image,
      metadata,
      metadata_startup_script,
    ]
  }
}

resource "google_compute_disk" "volumes" {
  for_each = {
    for x, values in module.design.volumes : x => values if lookup(values, "managed", true)
  }
  name = "${var.cluster_name}-${each.key}"
  type = lookup(each.value, "type", "pd-standard")
  zone = local.zone
  size = each.value.size
}

data "google_compute_disk" "existing_volumes" {
  for_each = {
    for x, values in module.design.volumes : x => values if !lookup(values, "managed", true)
  }
  name = "${var.cluster_name}-${each.key}"
}

locals {
  volume_self_links = {
    for key, values in module.design.volumes :
    key => lookup(values, "managed", true) ? google_compute_disk.volumes[key].self_link : data.google_compute_disk.existing_volumes[key].self_link
  }
  volume_device_names = {
    for key, values in module.design.volumes :
    key => lookup(values, "managed", true) ? google_compute_disk.volumes[key].name : data.google_compute_disk.existing_volumes[key].name
  }
}

resource "google_compute_attached_disk" "attachments" {
  for_each    = module.design.volumes
  disk        = local.volume_self_links[each.key]
  device_name = local.volume_device_names[each.key]
  mode        = "READ_WRITE"
  instance    = google_compute_instance.instances[each.value.instance].self_link
}

locals {
  inventory = { for x, values in module.design.instances :
    x => {
      public_ip = contains(values.tags, "public") ? google_compute_address.public_ip[x].address : ""
      local_ip  = google_compute_address.nic[x].address
      prefix    = values.prefix
      tags      = values.tags
      specs = merge({
        cpus = data.external.machine_type[values["prefix"]].result["vcpus"]
        ram  = data.external.machine_type[values["prefix"]].result["ram"]
        gpus = try(data.external.machine_type[values["prefix"]].result["gpus"], 0)
      }, values.specs)
      volumes = contains(keys(module.design.volume_per_instance), x) ? {
        for pv_key, pv_values in var.volumes :
        pv_key => {
          for name, specs in pv_values :
          name => merge(
            { glob = "/dev/disk/by-id/google-${var.cluster_name}-${x}-${pv_key}-${name}" },
            specs,
          )
        } if contains(values.tags, pv_key)
      } : {}
    }
  }

  post_inventory = { for host, values in local.inventory :
    host => merge(values, {
      id = try(google_compute_instance.instances[host].id, "")
    })
  }
}

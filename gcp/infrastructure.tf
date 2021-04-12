provider "google" {
  project = var.project
  region  = var.region
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

resource "google_compute_instance" "instances" {
  for_each = local.instances
  project  = var.project
  zone     = local.zone

  name         = format("%s-%s", var.cluster_name, each.key)
  machine_type = each.value.type
  tags         = each.value.tags

  boot_disk {
    initialize_params {
      image = var.image
      type  = "pd-ssd"
      size  = var.root_disk_size
    }
  }

  scheduling {
    # Instances with guest accelerators do not support live migration.
    on_host_maintenance = lookup(each.value, "gpu_count", 0) > 0 ? "TERMINATE" : "MIGRATE"
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
    user-data          = base64gzip(local.user_data[each.key])
    user-data-encoding = "base64"
    VmDnsSetting       = "ZonalOnly"
  }

  metadata_startup_script = file("${path.module}/install_cloudinit.sh")

  lifecycle {
    ignore_changes = [
      attached_disk,
      boot_disk[0].initialize_params[0].image
    ]
  }
}

resource "google_compute_disk" "volumes" {
  for_each = local.volumes
  name     = "${var.cluster_name}-${each.key}"
  type     = lookup(each.value, "type", "pd-standard")
  zone     = local.zone
  size     = each.value.size
}

resource "google_compute_attached_disk" "attachments" {
  for_each    = local.volumes
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
      kj => [for key, volume in local.volumes :
        "/dev/disk/by-id/google-${var.cluster_name}-${volume["instance"]}-${ki}-${kj}"
        if key == "${volume["instance"]}-${ki}-${kj}"
      ]
    }
  }
}

locals {
  puppetserver_id = try(element([for x, values in local.instances : google_compute_instance.instances[x].id if contains(values.tags, "puppet")], 0), "")
  all_instances = { for x, values in local.instances :
    x => {
      public_ip = contains(values["tags"], "public") ? local.public_ip[x] : ""
      local_ip  = google_compute_address.nic[x].address
      tags      = values["tags"]
      id        = google_compute_instance.instances[x].id
      hostkeys = {
        rsa = tls_private_key.rsa_hostkeys[local.host2prefix[x]].public_key_openssh
      }
    }
  }
}

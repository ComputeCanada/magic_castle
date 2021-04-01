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

resource "google_compute_network" "network" {
  name = "${var.cluster_name}-network"
}

resource "google_compute_subnetwork" "subnet" {
  name          = "${var.cluster_name}-subnet"
  network       = google_compute_network.network.self_link
  ip_cidr_range = "10.0.0.0/16"
  region        = var.region
}

resource "google_compute_router" "router" {
  name    = "${var.cluster_name}-router"
  region  = var.region
  network = google_compute_network.network.self_link
  bgp {
    asn = 64514
  }
}

resource "google_compute_router_nat" "nat" {
  name                               = "${var.cluster_name}-nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

resource "google_compute_disk" "disks" {
  for_each = local.volumes
  name     = "${var.cluster_name}-${each.key}"
  type     = lookup(each.value, "type", "pd-standard")
  zone     = local.zone
  size     = each.value.size
}

resource "google_compute_address" "internal" {
  for_each     = local.instances
  name         = format("%s-%s-ipv4", var.cluster_name, each.key)
  address_type = "INTERNAL"
  subnetwork   = google_compute_subnetwork.subnet.self_link
  region       = var.region
}

resource "google_compute_address" "public" {
  for_each = { for x, values in local.instances : x => true if contains(values.tags, "public") }
  name     = format("%s-%s-public-ipv4", var.cluster_name, each.key)
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
    network_ip = google_compute_address.internal[each.key].address
    access_config {
      nat_ip = contains(each.value.tags, "public") ? google_compute_address.public[each.key].address : null
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

resource "google_compute_attached_disk" "attachments" {
  for_each    = local.volumes
  disk        = google_compute_disk.disks[each.key].self_link
  device_name = google_compute_disk.disks[each.key].name
  mode        = "READ_WRITE"
  instance    = google_compute_instance.instances[each.value.instance].self_link
}

resource "google_compute_firewall" "allow_all_internal" {
  name    = format("%s-allow-all-internal", var.cluster_name)
  network = google_compute_network.network.self_link

  source_ranges = [google_compute_subnetwork.subnet.ip_cidr_range]

  allow {
    protocol = "tcp"
  }

  allow {
    protocol = "udp"
  }

  allow {
    protocol = "icmp"
  }

}

resource "google_compute_firewall" "default" {
  count   = length(var.firewall_rules)
  name    = format("%s-%s", var.cluster_name, lower(var.firewall_rules[count.index].name))
  network = google_compute_network.network.self_link

  source_ranges = [var.firewall_rules[count.index].cidr]

  allow {
    protocol = var.firewall_rules[count.index].ip_protocol
    ports = [var.firewall_rules[count.index].from_port != var.firewall_rules[count.index].to_port ?
      "${var.firewall_rules[count.index].from_port}-${var.firewall_rules[count.index].to_port}" :
      var.firewall_rules[count.index].from_port
    ]
  }

  target_tags = ["public"]
}

locals {
  volume_devices = {
    for ki, vi in var.storage :
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
  public_ip = {
    for x, values in local.instances : x => google_compute_address.public[x].address
    if contains(values.tags, "public")
  }
  puppetmaster_ip = [for x, values in local.instances : google_compute_address.internal[x].address if contains(values.tags, "puppet")]
  puppetmaster_id = try(element([for x, values in local.instances : google_compute_instance.instances[x].id if contains(values.tags, "puppet")], 0), "")
  all_instances = { for x, values in local.instances :
    x => {
      public_ip = contains(values["tags"], "public") ? local.public_ip[x] : ""
      local_ip  = google_compute_address.internal[x].address
      tags      = values["tags"]
      id        = google_compute_instance.instances[x].id
      hostkeys = {
        rsa = tls_private_key.rsa_hostkeys[local.host2prefix[x]].public_key_openssh
      }
    }
  }
}

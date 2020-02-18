provider "google" {
  project = var.project_name
  region  = var.region
  #  version = "~> 2.1.0"
}

data "google_compute_zones" "available" {
  status = "UP"
}

resource "random_shuffle" "random_zone" {
  input = data.google_compute_zones.available.names
  result_count = 1
}

locals {
  zone = (
    ( var.zone != "" &&
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

resource "google_compute_disk" "home" {
  count = lower(var.storage["type"]) == "nfs" ? 1 : 0
  name  = "${var.cluster_name}-home"
  type  = "pd-standard"
  zone  = local.zone
  size  = var.storage["home_size"]
}

resource "google_compute_disk" "project" {
  count = lower(var.storage["type"]) == "nfs" ? 1 : 0
  name  = "${var.cluster_name}-project"
  type  = "pd-standard"
  zone  = local.zone
  size  = var.storage["project_size"]
}

resource "google_compute_disk" "scratch" {
  count = lower(var.storage["type"]) == "nfs" ? 1 : 0
  name  = "${var.cluster_name}-scratch"
  type  = "pd-standard"
  zone  = local.zone
  size  = var.storage["scratch_size"]
}

resource "google_compute_address" "mgmt" {
  count        = var.instances["mgmt"]["count"]
  name         = format("%s-mgmt%d-ipv4", var.cluster_name, count.index + 1)
  address_type = "INTERNAL"
  subnetwork   = google_compute_subnetwork.subnet.self_link
  region       = var.region
}

resource "google_compute_instance" "mgmt" {
  project      = var.project_name
  zone         = local.zone
  count        = var.instances["mgmt"]["count"]
  name         = format("%s-mgmt%d", var.cluster_name, count.index + 1)
  machine_type = var.instances["mgmt"]["type"]
  tags         = ["mgmt"]

  boot_disk {
    initialize_params {
      image = var.image
      type  = "pd-ssd"
      size  = var.root_disk_size
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.self_link
    network_ip = google_compute_address.mgmt[count.index].address
    access_config {
    }
  }

  metadata = {
    user-data          = data.template_cloudinit_config.mgmt_config[count.index].rendered
    user-data-encoding = "base64"
  }

  metadata_startup_script = file("${path.module}/install_cloudinit.sh")

  lifecycle {
    ignore_changes = [
      attached_disk,
      boot_disk[0].initialize_params[0].image
    ]
  }
}

resource "google_compute_attached_disk" "home" {
  count       = (lower(var.storage["type"]) == "nfs" && var.instances["mgmt"]["count"] > 0) ? 1 : 0
  disk        = google_compute_disk.home[0].self_link
  device_name = google_compute_disk.home[0].name
  mode        = "READ_WRITE"
  instance    = google_compute_instance.mgmt[0].self_link
}

resource "google_compute_attached_disk" "project" {
  count       = (lower(var.storage["type"]) == "nfs" && var.instances["mgmt"]["count"] > 0) ? 1 : 0
  disk        = google_compute_disk.project[0].self_link
  device_name = google_compute_disk.project[0].name
  mode        = "READ_WRITE"
  instance    = google_compute_instance.mgmt[0].self_link
}

resource "google_compute_attached_disk" "scratch" {
  count       = (lower(var.storage["type"]) == "nfs" && var.instances["mgmt"]["count"] > 0) ? 1 : 0
  disk        = google_compute_disk.scratch[0].self_link
  device_name = google_compute_disk.scratch[0].name
  mode        = "READ_WRITE"
  instance    = google_compute_instance.mgmt[0].self_link
}

resource "google_compute_address" "static" {
  count = max(var.instances["login"]["count"], 1)
  name  = format("%s-login%d-ipv4",  var.cluster_name, count.index + 1)
}

resource "google_compute_instance" "login" {
  count        = var.instances["login"]["count"]
  project      = var.project_name
  zone         = local.zone
  name         = format("%s-login%d", var.cluster_name, count.index + 1)
  machine_type = var.instances["login"]["type"]
  tags         = ["login"]

  boot_disk {
    initialize_params {
      image = var.image
      type  = "pd-ssd"
      size  = var.root_disk_size
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.self_link
    access_config {
      nat_ip = google_compute_address.static[count.index].address
    }
  }

  metadata = {
    user-data          = data.template_cloudinit_config.login_config[count.index].rendered
    user-data-encoding = "base64"
  }

  metadata_startup_script = file("${path.module}/install_cloudinit.sh")

  lifecycle {
    ignore_changes = [
      boot_disk[0].initialize_params[0].image
    ]
  }
}

resource "google_compute_instance" "node" {
  count        = var.instances["node"]["count"]
  project      = var.project_name
  zone         = local.zone
  name         = format("%s-node%d", var.cluster_name, count.index + 1)
  machine_type = var.instances["node"]["type"]
  scheduling {
    # Instances with guest accelerators do not support live migration.
    on_host_maintenance = var.gpu_per_node["count"] > 0 ? "TERMINATE" : "MIGRATE"
  }
  guest_accelerator {
    type  = var.gpu_per_node["type"]
    count = var.gpu_per_node["count"]
  }
  tags = ["node"]

  boot_disk {
    initialize_params {
      image = var.image
      type  = "pd-ssd"
      size  = var.root_disk_size
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.self_link
  }

  metadata = {
    user-data          = data.template_cloudinit_config.node_config[count.index].rendered
    user-data-encoding = "base64"
  }

  metadata_startup_script = file("${path.module}/install_cloudinit.sh")

  lifecycle {
    ignore_changes = [
      boot_disk[0].initialize_params[0].image
    ]
  }
}

resource "google_compute_firewall" "allow_all_internal" {
  name = format("%s-allow-all-internal", var.cluster_name)
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
    ports    = [ var.firewall_rules[count.index].from_port != var.firewall_rules[count.index].to_port ?
                 "${var.firewall_rules[count.index].from_port}-${var.firewall_rules[count.index].to_port}" :
                 var.firewall_rules[count.index].from_port
    ]
  }

  target_tags = ["login"]
}

locals {
  mgmt1_ip   = google_compute_address.mgmt[0].address
  public_ip   = google_compute_address.static[*].address
  home_dev    = lower(var.storage["type"]) == "nfs" ? "/dev/disk/by-id/google-${google_compute_disk.home[0].name}" : ""
  project_dev = lower(var.storage["type"]) == "nfs" ? "/dev/disk/by-id/google-${google_compute_disk.project[0].name}" : ""
  scratch_dev = lower(var.storage["type"]) == "nfs" ? "/dev/disk/by-id/google-${google_compute_disk.scratch[0].name}" : ""
}

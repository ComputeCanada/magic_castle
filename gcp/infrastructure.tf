provider "google" {
  project = var.project_name
  region  = var.region
  #  version = "~> 2.1.0"
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
  name  = "home"
  type  = "pd-standard"
  zone  = var.zone
  size  = var.storage["home_size"]
}

resource "google_compute_disk" "project" {
  count = lower(var.storage["type"]) == "nfs" ? 1 : 0
  name  = "project"
  type  = "pd-standard"
  zone  = var.zone
  size  = var.storage["project_size"]
}

resource "google_compute_disk" "scratch" {
  count = lower(var.storage["type"]) == "nfs" ? 1 : 0
  name  = "scratch"
  type  = "pd-standard"
  zone  = var.zone
  size  = var.storage["scratch_size"]
}

resource "google_compute_address" "mgmt" {
  count        = var.nb_mgmt
  name         = format("mgmt%02d", count.index + 1)
  address_type = "INTERNAL"
  subnetwork   = google_compute_subnetwork.subnet.self_link
  region       = var.region
}

resource "google_compute_instance" "mgmt" {
  project      = var.project_name
  zone         = var.zone
  count        = var.nb_mgmt
  name         = format("mgmt%02d", count.index + 1)
  machine_type = var.machine_type_mgmt
  tags         = [format("mgmt%02d", count.index + 1)]

  boot_disk {
    initialize_params {
      image = var.gcp_image
      type  = "pd-ssd"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.self_link
    network_ip = google_compute_address.mgmt[count.index].address
    access_config {
    }
  }

  metadata = {
    sshKeys            = "centos:${file(var.public_key_path)}"
    user-data          = data.template_cloudinit_config.mgmt_config[count.index].rendered
    user-data-encoding = "base64"
  }

  metadata_startup_script = file("${path.module}/install_cloudinit.sh")

  lifecycle {
    ignore_changes = [attached_disk]
  }
}

resource "google_compute_attached_disk" "home" {
  count       = (lower(var.storage["type"]) == "nfs" && var.nb_mgmt > 0) ? 1 : 0
  disk        = google_compute_disk.home[0].self_link
  device_name = google_compute_disk.home[0].name
  mode        = "READ_WRITE"
  instance    = google_compute_instance.mgmt[0].self_link
}

resource "google_compute_attached_disk" "project" {
  count       = (lower(var.storage["type"]) == "nfs" && var.nb_mgmt > 0) ? 1 : 0
  disk        = google_compute_disk.project[0].self_link
  device_name = google_compute_disk.project[0].name
  mode        = "READ_WRITE"
  instance    = google_compute_instance.mgmt[0].self_link
}

resource "google_compute_attached_disk" "scratch" {
  count       = (lower(var.storage["type"]) == "nfs" && var.nb_mgmt > 0) ? 1 : 0
  disk        = google_compute_disk.scratch[0].self_link
  device_name = google_compute_disk.scratch[0].name
  mode        = "READ_WRITE"
  instance    = google_compute_instance.mgmt[0].self_link
}

resource "google_compute_address" "static" {
  count = max(var.nb_login, 1)
  name  = format("login%02d-ipv4", count.index + 1)
}

resource "google_compute_instance" "login" {
  count        = var.nb_login
  project      = var.project_name
  zone         = var.zone
  name         = format("login%02d", count.index + 1)
  machine_type = var.machine_type_login
  tags         = [format("login%02d", count.index + 1)]

  boot_disk {
    initialize_params {
      image = var.gcp_image
      type  = "pd-ssd"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.self_link
    access_config {
      nat_ip = google_compute_address.static[count.index].address
    }
  }

  metadata = {
    sshKeys            = "centos:${file(var.public_key_path)}"
    user-data          = data.template_cloudinit_config.login_config[count.index].rendered
    user-data-encoding = "base64"
  }

  metadata_startup_script = file("${path.module}/install_cloudinit.sh")
}

resource "google_compute_instance" "node" {
  count        = var.nb_nodes
  project      = var.project_name
  zone         = var.zone
  name         = "node${count.index + 1}"
  machine_type = var.machine_type_node
  scheduling {
    # Instances with guest accelerators do not support live migration.
    on_host_maintenance = var.gpu_per_node[1] ? "TERMINATE" : "MIGRATE"
  }
  guest_accelerator {
    type  = var.gpu_per_node[0]
    count = var.gpu_per_node[1]
  }
  tags = ["node${count.index + 1}"]

  boot_disk {
    initialize_params {
      image = var.gcp_image
      type  = "pd-ssd"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.self_link
  }

  metadata = {
    sshKeys            = "centos:${file(var.public_key_path)}"
    user-data          = data.template_cloudinit_config.node_config[count.index].rendered
    user-data-encoding = "base64"
  }

  metadata_startup_script = file("${path.module}/install_cloudinit.sh")
}

resource "google_compute_firewall" "allow_all_internal" {
  name = "allow-all-internal"
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
  name    = lower(var.firewall_rules[count.index].name)
  network = google_compute_network.network.self_link

  source_ranges = [var.firewall_rules[count.index].cidr]

  allow {
    protocol = var.firewall_rules[count.index].ip_protocol
    ports    = [ var.firewall_rules[count.index].from_port != var.firewall_rules[count.index].to_port ?
                 "${var.firewall_rules[count.index].from_port}-${var.firewall_rules[count.index].to_port}" :
                 var.firewall_rules[count.index].from_port
    ]
  }

  target_tags = google_compute_instance.login[*].name
}

locals {
  mgmt01_ip   = google_compute_address.mgmt[0].address
  public_ip   = google_compute_address.static[*].address
  home_dev    = "/dev/disk/by-id/google-home"
  project_dev = "/dev/disk/by-id/google-project"
  scratch_dev = "/dev/disk/by-id/google-scratch"
}

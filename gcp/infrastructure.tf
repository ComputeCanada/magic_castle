provider "google" {
  project = var.project_name
  region  = var.region
  #  version = "~> 2.1.0"
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

resource "google_compute_address" "mgmt01" {
  name         = "mgmt01"
  address_type = "INTERNAL"
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
    subnetwork = "default"
    network_ip = google_compute_address.mgmt01.address
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
    subnetwork = "default"
    access_config {
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
    subnetwork = "default"
    access_config {
    }
  }

  metadata = {
    sshKeys            = "centos:${file(var.public_key_path)}"
    user-data          = data.template_cloudinit_config.node_config[count.index].rendered
    user-data-encoding = "base64"
  }

  metadata_startup_script = file("${path.module}/install_cloudinit.sh")
}

resource "google_compute_firewall" "default" {
  count   = length(var.firewall_rules)
  name    = lower(var.firewall_rules[count.index].name)
  network = "default"

  source_ranges = [var.firewall_rules[count.index].cidr]

  allow {
    protocol = var.firewall_rules[count.index].ip_protocol
    ports    = ["${var.firewall_rules[count.index].from_port}-${var.firewall_rules[count.index].to_port}"]
  }

  target_tags = google_compute_instance.login[*].name
}

locals {
  mgmt01_ip   = google_compute_address.mgmt01.address
  public_ip   = google_compute_instance.login[*].network_interface[0].access_config[0].nat_ip
  cidr        = "10.128.0.0/9" # GCP default
  home_dev    = "/dev/disk/by-id/google-home"
  project_dev = "/dev/disk/by-id/google-project"
  scratch_dev = "/dev/disk/by-id/google-scratch"
}

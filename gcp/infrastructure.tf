provider "google" {
  project = "${var.project_name}"
  region  = "${var.zone}"
  version = "~> 2.1.0"
}

resource "google_compute_disk" "home" {
  name = "home"
  type = "pd-standard"
  zone = "${var.zone_region}"
  size = "${var.home_size}"
}

resource "google_compute_disk" "project" {
  name = "project"
  type = "pd-standard"
  zone = "${var.zone_region}"
  size = "${var.project_size}"
}

resource "google_compute_disk" "scratch" {
  name = "scratch"
  type = "pd-standard"
  zone = "${var.zone_region}"
  size = "${var.scratch_size}"
}

resource "google_compute_instance" "mgmt" {
  project      = "${var.project_name}"
  zone         = "${var.zone_region}"
  count        = "${var.nb_mgmt}"
  name         = "${format("mgmt%02d", count.index + 1)}"
  machine_type = "${var.machine_type_mgmt}"
  tags         = ["${format("mgmt%02d", count.index + 1)}"]

  boot_disk {
    initialize_params {
      image = "${var.gcp_image}"
    }
  }

  network_interface {
    subnetwork = "default"
    access_config { }
  }

  metadata {
    sshKeys            = "centos:${file(var.public_key_path)}"
    user-data          = "${element(data.template_cloudinit_config.mgmt_config.*.rendered, count.index)}"
    user-data-encoding = "base64"
  }

  metadata_startup_script = "${file("${path.module}/install_cloudinit.sh")}"

  lifecycle {
    ignore_changes = ["attached_disk"]
  }
}

resource "google_compute_attached_disk" "home" {
  count       = "${var.nb_mgmt > 0 ? 1 : 0}"
  disk        = "${google_compute_disk.home.self_link}"
  device_name = "${google_compute_disk.home.name}"
  mode        = "READ_WRITE"
  instance    = "${google_compute_instance.mgmt.0.self_link}"
}

resource "google_compute_attached_disk" "project" {
  count       = "${var.nb_mgmt > 0 ? 1 : 0}"
  disk        = "${google_compute_disk.project.self_link}"
  device_name = "${google_compute_disk.project.name}"
  mode        = "READ_WRITE"
  instance    = "${google_compute_instance.mgmt.0.self_link}"
}

resource "google_compute_attached_disk" "scratch" {
  count       = "${var.nb_mgmt > 0 ? 1 : 0}"
  disk        = "${google_compute_disk.scratch.self_link}"
  device_name = "${google_compute_disk.scratch.name}"
  mode        = "READ_WRITE"
  instance    = "${google_compute_instance.mgmt.0.self_link}"
}

resource "google_compute_instance" "login" {
  project      = "${var.project_name}"
  zone         = "${var.zone_region}"
  name         = "${format("login%02d", count.index + 1)}"
  machine_type = "${var.machine_type_login}"
  tags         = ["${format("login%02d", count.index + 1)}"]

  boot_disk {
    initialize_params {
      image = "${var.gcp_image}"
    }
  }

  network_interface {
    subnetwork = "default"
    access_config { }
  }

  metadata {
    sshKeys            = "centos:${file(var.public_key_path)}"
    user-data          = "${element(data.template_cloudinit_config.login_config.*.rendered, count.index)}"
    user-data-encoding = "base64"
  }

  metadata_startup_script = "${file("${path.module}/install_cloudinit.sh")}"
}

resource "google_compute_instance" "node" {
  count        = "${var.nb_nodes}"
  project      = "${var.project_name}"
  zone         = "${var.zone_region}"
  name         = "node${count.index + 1}"
  machine_type = "${var.machine_type_node}"
  scheduling {
    # Instances with guest accelerators do not support live migration.
    on_host_maintenance = "${var.gpu_per_node[1] ? "TERMINATE" : "MIGRATE"}"
  }
  guest_accelerator {
    type  = "${var.gpu_per_node[0]}"
    count = "${var.gpu_per_node[1]}"
  }
  tags         = ["node${count.index + 1}"]

  boot_disk {
    initialize_params {
      image = "${var.gcp_image}"
    }
  }

  network_interface {
    subnetwork = "default"
    access_config { }
  }

  metadata {
    sshKeys            = "centos:${file(var.public_key_path)}"
    user-data          = "${element(data.template_cloudinit_config.node_config.*.rendered, count.index)}"
    user-data-encoding = "base64"
  }

  metadata_startup_script = "${file("${path.module}/install_cloudinit.sh")}"
}

resource "google_compute_firewall" "default" {
  name    = "firewall"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  target_tags   = ["${google_compute_instance.login.0.name}"]
}

locals {
  mgmt01_ip = "${google_compute_instance.mgmt.0.network_interface.0.network_ip}"
  public_ip = "${google_compute_instance.login.0.network_interface.0.access_config.0.nat_ip}"
  cidr = "10.128.0.0/9" # GCP default
  home_dev    = "/dev/disk/by-id/google-home"
  project_dev = "/dev/disk/by-id/google-project"
  scratch_dev = "/dev/disk/by-id/google-scratch"
}

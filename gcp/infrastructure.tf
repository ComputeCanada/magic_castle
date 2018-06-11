provider "google" {
  credentials = "${file(var.credentials_file)}"
  project     = "${var.project_name}"
  region      = "${var.zone}"
}


resource "google_compute_instance" "mgmt01" {
  project = "${var.project_name}"
  zone = "${var.zone_region}"
  name = "mgmt01"
  machine_type = "${var.machine_type_mgmt}"
  tags         = ["mgmt01"]

  boot_disk {
    initialize_params {
      image = "centos-7"
      size  = "${var.shared_storage_size}"
    }
  }

  network_interface {
	network = "default"
	access_config {
	}
  }

  metadata {
    sshKeys = "centos:${file(var.public_key_path)}"
    user-data = "${data.template_cloudinit_config.mgmt_config.rendered}"
    user-data-encoding = "base64"
  }

  metadata_startup_script = <<-EOF
              #!/bin/bash
              if yum -q list installed "cloud-init" >/dev/null 2>&1; then
                true
              else
                sudo yum -y install cloud-init
                sudo reboot
              fi
              rm -f /etc/dhcp/dhclient.d/google_hostname.sh
              EOF
}

resource "google_compute_instance" "login01" {
  project = "${var.project_name}"
  zone = "${var.zone_region}"
  name = "login01"
  machine_type = "${var.machine_type_login}"
  tags         = ["login01"]

  boot_disk {
    initialize_params {
      image = "centos-7"
    }
  }

  network_interface {
	network = "default"
	access_config {
	}
  }

  metadata {
    sshKeys = "centos:${file(var.public_key_path)}"
    user-data = "${data.template_cloudinit_config.login_config.rendered}"
    user-data-encoding = "base64"
  }

  metadata_startup_script = <<-EOF
              #!/bin/bash
              if yum -q list installed "cloud-init" >/dev/null 2>&1; then
                true
              else
                sudo yum -y install cloud-init
                sudo reboot
              fi
              rm -f /etc/dhcp/dhclient.d/google_hostname.sh
              EOF
}

resource "google_compute_instance" "node" {
  count = "${var.nb_nodes}"
  project = "${var.project_name}"
  zone = "${var.zone_region}"
  name = "node${count.index + 1}"
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
      image = "centos-7"
    }
  }

  network_interface {
	network = "default"
	access_config {
	}
  }

  metadata {
    sshKeys = "centos:${file(var.public_key_path)}"
    user-data = "${element(data.template_cloudinit_config.node_config.*.rendered, count.index)}"  
    user-data-encoding = "base64"
  }

  metadata_startup_script = <<-EOF
              #!/bin/bash
              if yum -q list installed "cloud-init" >/dev/null 2>&1; then
                true
              else
                sudo yum -y install cloud-init
                sudo reboot
              fi
              rm -f /etc/dhcp/dhclient.d/google_hostname.sh
              EOF
}

resource "google_compute_firewall" "default" {
  name    = "firewall"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  target_tags   = ["login01"]
}

locals {
  mgmt01_ip = "${google_compute_instance.mgmt01.network_interface.0.address}"
  public_ip = "${google_compute_instance.login01.network_interface.0.access_config.0.assigned_nat_ip}"
  cidr = "10.128.0.0/9" # GCP default
}

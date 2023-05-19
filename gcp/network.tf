resource "google_compute_network" "network" {
  name = "${var.cluster_name}-network"
}

resource "google_compute_subnetwork" "subnet" {
  name          = "${var.cluster_name}-subnet"
  network       = google_compute_network.network.self_link
  ip_cidr_range = "10.0.0.0/24"
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

resource "google_compute_address" "nic" {
  for_each     = module.design.instances
  name         = format("%s-%s-ipv4", var.cluster_name, each.key)
  address_type = "INTERNAL"
  subnetwork   = google_compute_subnetwork.subnet.self_link
  region       = var.region
}

resource "google_compute_address" "public_ip" {
  for_each = { for x, values in module.design.instances : x => true if contains(values.tags, "public") }
  name     = format("%s-%s-public-ipv4", var.cluster_name, each.key)
}

locals {
  puppetservers = {
      for x, values in module.design.instances : x => google_compute_address.nic[x].address
      if contains(values.tags, "puppet")
  }
}
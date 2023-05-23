resource "openstack_compute_secgroup_v2" "secgroup" {
  name        = "${var.cluster_name}-secgroup"
  description = "${var.cluster_name} security group"

  rule {
    from_port   = -1
    to_port     = -1
    ip_protocol = "icmp"
    self        = true
  }

  rule {
    from_port   = 1
    to_port     = 65535
    ip_protocol = "tcp"
    self        = true
  }

  rule {
    from_port   = 1
    to_port     = 65535
    ip_protocol = "udp"
    self        = true
  }

  dynamic "rule" {
    for_each = var.firewall_rules
    content {
      from_port   = rule.value.from_port
      to_port     = rule.value.to_port
      ip_protocol = rule.value.ip_protocol
      cidr        = rule.value.cidr
    }
  }
}

resource "openstack_networking_port_v2" "nic" {
  for_each              = module.design.instances
  name                  = format("%s-%s-port", var.cluster_name, each.key)
  network_id            = local.network.id
  security_group_ids    = [openstack_compute_secgroup_v2.secgroup.id]
  port_security_enabled = true
  fixed_ip {
    subnet_id = local.subnet.id
  }
}

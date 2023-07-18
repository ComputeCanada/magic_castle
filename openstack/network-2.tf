resource "openstack_networking_secgroup_v2" "secgroup" {
  name        = "${var.cluster_name}-secgroup"
  description = "${var.cluster_name} security group"
}

resource openstack_networking_secgroup_rule_v2 "icmp" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  description       = "internal icmp"
  security_group_id = openstack_networking_secgroup_v2.secgroup.id
  remote_group_id   = openstack_networking_secgroup_v2.secgroup.id
}

resource openstack_networking_secgroup_rule_v2 "tcp" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  description       = "internal tcp"
  security_group_id = openstack_networking_secgroup_v2.secgroup.id
  remote_group_id   = openstack_networking_secgroup_v2.secgroup.id
}

resource openstack_networking_secgroup_rule_v2 "udp" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "udp"
  description       = "internal udp"
  security_group_id = openstack_networking_secgroup_v2.secgroup.id
  remote_group_id   = openstack_networking_secgroup_v2.secgroup.id
}

resource openstack_networking_secgroup_rule_v2 "rule" {
  for_each = var.firewall_rules

  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = each.value.ip_protocol
  port_range_min    = each.value.from_port
  port_range_max    = each.value.to_port
  remote_ip_prefix  = each.value.cidr
  description       = each.key
  security_group_id = openstack_networking_secgroup_v2.secgroup.id
}

resource "openstack_networking_port_v2" "nic" {
  for_each           = module.design.instances
  name               = format("%s-%s-port", var.cluster_name, each.key)
  network_id         = local.network.id
  security_group_ids = [openstack_networking_secgroup_v2.secgroup.id]
  fixed_ip {
    subnet_id = local.subnet.id
  }
}

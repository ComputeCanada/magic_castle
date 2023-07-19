resource "openstack_networking_secgroup_v2" "global" {
  name        = "${var.cluster_name}-secgroup"
  description = "${var.cluster_name} global security group"
}

resource openstack_networking_secgroup_rule_v2 "icmp" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  description       = "internal allow all icmp"
  security_group_id = openstack_networking_secgroup_v2.global.id
  remote_group_id   = openstack_networking_secgroup_v2.global.id
}

resource openstack_networking_secgroup_rule_v2 "tcp" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  description       = "internal allow all tcp"
  security_group_id = openstack_networking_secgroup_v2.global.id
  remote_group_id   = openstack_networking_secgroup_v2.global.id
}

resource openstack_networking_secgroup_rule_v2 "udp" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "udp"
  description       = "internal allow all udp"
  security_group_id = openstack_networking_secgroup_v2.global.id
  remote_group_id   = openstack_networking_secgroup_v2.global.id
}

locals {
  all_tags   = toset(flatten([ for key, value in module.design.instances: value.tags ]))
  sec_groups = toset([ for name, rule in var.firewall_rules: rule.tag if contains(local.all_tags, rule.tag) ])
}

resource "openstack_networking_secgroup_v2" "external" {
  for_each    = local.sec_groups
  name        = "${var.cluster_name}-secgroup-${each.key}"
  description = "${var.cluster_name} external security group for ${each.key} instances"
  tags        = [each.key]
}

resource openstack_networking_secgroup_rule_v2 "rule" {
  for_each = { for name, rule in var.firewall_rules: name => rule if contains(local.sec_groups, rule.tag) }

  direction         = "ingress"
  ethertype         = each.value.ethertype
  protocol          = each.value.protocol
  port_range_min    = each.value.from_port
  port_range_max    = each.value.to_port
  remote_ip_prefix  = each.value.cidr
  description       = each.key
  security_group_id = openstack_networking_secgroup_v2.external[each.value.tag].id
}

resource "openstack_networking_port_v2" "nic" {
  for_each           = module.design.instances
  name               = format("%s-%s-port", var.cluster_name, each.key)
  network_id         = local.network.id
  security_group_ids = concat(
    [
      openstack_networking_secgroup_v2.global.id
    ],
    [
      for tag, value in openstack_networking_secgroup_v2.external: value.id if contains(each.value.tags, tag)
    ]
  )
  fixed_ip {
    subnet_id = local.subnet.id
  }
}

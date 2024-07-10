# Create virtual network
resource "azurerm_virtual_network" "network" {
  name                = "${var.cluster_name}_vnet"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = local.resource_group_name
}

# Create subnet
resource "azurerm_subnet" "subnet" {
  name                 = "${var.cluster_name}_subnet"
  resource_group_name  = local.resource_group_name
  virtual_network_name = azurerm_virtual_network.network.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "public_ip" {
  for_each            = module.design.instances
  name                = format("%s-%s-public-ipv4", var.cluster_name, each.key)
  location            = var.location
  resource_group_name = local.resource_group_name
  allocation_method   = contains(each.value.tags, "public") ? "Static" : "Dynamic"
}

# Build a list of tag sets that include firewall rule tags
locals {
  fw_tags = toset([ for key, value in var.firewall_rules: value.tag ])
  fw_sets = {
    for tags in distinct([for key, values in module.design.instances: toset(setintersection(values.tags, local.fw_tags))]):
      join("-", toset(tags)) => toset(tags)
      if length(tags) > 0
  }
}

# Create Network Security Groups and rules
resource "azurerm_network_security_group" "external" {
  for_each            = local.fw_sets
  name                = "${var.cluster_name}_${each.key}_firewall"
  location            = var.location
  resource_group_name = local.resource_group_name

  dynamic "security_rule" {
    for_each = { for name, rule in var.firewall_rules: name => rule if contains(each.value, rule.tag) }
    iterator = rule
    content {
      name                       = rule.key
      priority                   = (100 + rule.value.from_port) % 4096
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = title(rule.value.protocol)
      source_port_range          = "*"
      destination_port_range     = "${rule.value.from_port}-${rule.value.to_port}"
      source_address_prefix      = "*"
      destination_address_prefix = rule.value.cidr
    }
  }
}

# Create network interface
resource "azurerm_network_interface" "nic" {
  for_each            = module.design.instances
  name                = format("%s-%s-nic", var.cluster_name, each.key)
  location            = var.location
  resource_group_name = local.resource_group_name

  ip_configuration {
    name                          = format("%s-%s-nic_config", var.cluster_name, each.key)
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip[each.key].id
  }
}

resource "azurerm_network_interface_security_group_association" "sg_assoc" {
 for_each                  = { for key, values in module.design.instances : key => values if can(local.fw_sets[join("-", toset(values.tags))]) }
 network_interface_id      = azurerm_network_interface.nic[each.key].id
 network_security_group_id = azurerm_network_security_group.external[join("-", toset(each.value.tags))].id
}

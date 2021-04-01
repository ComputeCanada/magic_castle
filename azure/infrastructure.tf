# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

# Check if user provided resource group is valid
data "azurerm_resource_group" "example" {
  count = var.azure_resource_group == "" ? 0 : 1
  name  = var.azure_resource_group
}

# Create a resource group
resource "azurerm_resource_group" "group" {
  count    = var.azure_resource_group == "" ? 1 : 0
  name     = "${var.cluster_name}_resource_group"
  location = var.location
}

# Create virtual network
resource "azurerm_virtual_network" "virtualNetwork" {
  name                = "${var.cluster_name}_vnet"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = local.resource_group_name
}

# Create subnet
resource "azurerm_subnet" "subnet" {
  name                 = "${var.cluster_name}_subnet"
  resource_group_name  = local.resource_group_name
  virtual_network_name = azurerm_virtual_network.virtualNetwork.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "public" {
  for_each            = local.instances
  name                = format("%s-%s-public-ipv4", var.cluster_name, each.key)
  location            = var.location
  resource_group_name = local.resource_group_name
  allocation_method   = contains(each.value.tags, "public") ? "Static" : "Dynamic"
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "public" {
  name                = "${var.cluster_name}_public-firewall"
  location            = var.location
  resource_group_name = local.resource_group_name

  dynamic "security_rule" {
    for_each = var.firewall_rules
    iterator = rule
    content {
      name                       = rule.value.name
      priority                   = (100 + rule.value.from_port) % 4096
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = title(rule.value.ip_protocol)
      source_port_range          = "*"
      destination_port_range     = "${rule.value.from_port}-${rule.value.to_port}"
      source_address_prefix      = "*"
      destination_address_prefix = rule.value.cidr
    }
  }
}

# Create network interface
resource "azurerm_network_interface" "nic" {
  for_each            = local.instances
  name                = format("%s-%s-nic", var.cluster_name, each.key)
  location            = var.location
  resource_group_name = local.resource_group_name

  ip_configuration {
    name                          = format("%s-%s-nic_config", var.cluster_name, each.key)
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = azurerm_public_ip.public[each.key].id
  }
}

resource "azurerm_network_interface_security_group_association" "public" {
  for_each                  = { for x, values in local.instances : x => true if contains(values.tags, "public") }
  network_interface_id      = azurerm_network_interface.nic[each.key].id
  network_security_group_id = azurerm_network_security_group.public.id
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "instances" {
  for_each              = local.instances
  size                  = each.value.type
  name                  = format("%s-%s", var.cluster_name, each.key)
  location              = var.location
  resource_group_name   = local.resource_group_name
  network_interface_ids = [azurerm_network_interface.nic[each.key].id]

  os_disk {
    name                 = format("%s-%s-disk", var.cluster_name, each.key)
    caching              = "ReadWrite"
    storage_account_type = var.managed_disk_type
    disk_size_gb         = var.root_disk_size
  }

  dynamic "source_image_reference" {
    for_each = can(tomap(var.image)) ? [var.image] : []
    iterator = key
    content {
      publisher = key.value["publisher"]
      offer     = key.value["offer"]
      sku       = key.value["sku"]
      version   = "latest"
    }
  }
  source_image_id = can(tomap(var.image)) ? null : tostring(var.image)

  computer_name  = each.key
  admin_username = "azure"
  custom_data    = base64gzip(local.user_data[each.key])

  disable_password_authentication = true
  dynamic "admin_ssh_key" {
    for_each = var.public_keys
    iterator = key
    content {
      username   = "azure"
      public_key = key.value
    }

  }

  lifecycle {
    ignore_changes = [
      source_image_reference,
      source_image_id
    ]
  }
}

resource "azurerm_managed_disk" "disks" {
  for_each             = local.volumes
  name                 = format("%s-%s", var.cluster_name, each.key)
  location             = var.location
  resource_group_name  = local.resource_group_name
  storage_account_type = lookup(each.value, "type", var.managed_disk_type)
  create_option        = "Empty"
  disk_size_gb         = each.value.size
}

resource "azurerm_virtual_machine_data_disk_attachment" "attachments" {
  for_each           = local.volumes
  managed_disk_id    = azurerm_managed_disk.disks[each.key].id
  virtual_machine_id = azurerm_linux_virtual_machine.instances[each.value.instance].id
  lun                = index(local.volume_per_instance[each.value.instance], replace(each.key, "${each.value.instance}-", ""))
  caching            = "ReadWrite"
}

locals {
  volume_devices = {
    for ki, vi in var.storage :
    ki => {
      for kj, vj in vi :
      kj => [for key, volume in local.volumes :
        "/dev/disk/azure/scsi1/lun${index(local.volume_per_instance[volume.instance], replace(key, "${volume.instance}-", ""))}"
        if key == "${volume["instance"]}-${ki}-${kj}"
      ]
    }
  }
}

locals {
  resource_group_name = var.azure_resource_group == "" ? azurerm_resource_group.group[0].name : var.azure_resource_group

  public_ip = {
    for x, values in local.instances : x => azurerm_public_ip.public[x].ip_address
    if contains(values.tags, "public")
  }
  puppetmaster_ip = [for x, values in local.instances : azurerm_network_interface.nic[x].private_ip_address if contains(values.tags, "puppet")]
  puppetmaster_id = try(element([for x, values in local.instances : azurerm_linux_virtual_machine.instances[x].id if contains(values.tags, "puppet")], 0), "")
  all_instances = { for x, values in local.instances :
    x => {
      public_ip = azurerm_public_ip.public[x].ip_address
      local_ip  = azurerm_network_interface.nic[x].private_ip_address
      tags      = values["tags"]
      id        = azurerm_linux_virtual_machine.instances[x].id
      hostkeys = {
        rsa = tls_private_key.rsa_hostkeys[local.host2prefix[x]].public_key_openssh
      }
    }
  }
}

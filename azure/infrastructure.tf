# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

# Check if user provided resource group is valid
data "azurerm_resource_group" "example" {
  count = var.azure_resource_group == "" ? 0 : 1
  name = var.azure_resource_group
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
  address_prefix       = local.cidr
}

# Create public IPs
resource "azurerm_public_ip" "loginIP" {
  count                        = var.instances["login"]["count"]
  name                         = format("%s-login-ip-%d", var.cluster_name, count.index + 1)
  location                     = var.location
  resource_group_name          = local.resource_group_name
  allocation_method            = "Static"
}

resource "azurerm_public_ip" "mgmtIP" {
  count                        = var.instances["mgmt"]["count"]
  name                         = format("%s-mgmt-ip-%d", var.cluster_name, count.index + 1)
  location                     = var.location
  resource_group_name          = local.resource_group_name
  allocation_method            = "Dynamic"
}

resource "azurerm_public_ip" "nodeIP" {
  for_each            = local.node
  name                = format("%s-%s-ip", var.cluster_name, each.key)
  location            = var.location
  resource_group_name = local.resource_group_name
  allocation_method   = "Dynamic"
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "security_login" {
  name                = "${var.cluster_name}_login-firewall"
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

resource "azurerm_network_security_group" "security_mgmt" {
  name                = "${var.cluster_name}_mgmt-firewall"
  location            = var.location
  resource_group_name = local.resource_group_name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Create network interface
resource "azurerm_network_interface" "loginNIC" {
  count                     = var.instances["login"]["count"]
  name                      = format("%s-login%d-nic", var.cluster_name, count.index + 1)
  location                  = var.location
  resource_group_name       = local.resource_group_name

  ip_configuration {
    name                          = "${var.cluster_name}_login_nicconfig"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = azurerm_public_ip.loginIP[count.index].id
  }
}

resource "azurerm_network_interface_security_group_association" "loginSec" {
  count                     = var.instances["login"]["count"]
  network_interface_id      = azurerm_network_interface.loginNIC[count.index].id
  network_security_group_id = azurerm_network_security_group.security_login.id
}

resource "azurerm_network_interface" "mgmtNIC" {
  count                     = var.instances["mgmt"]["count"]
  name                      = format("%s-mgmt%d-nic", var.cluster_name, count.index + 1)
  location                  = var.location
  resource_group_name       = local.resource_group_name

  ip_configuration {
    name                          = "${var.cluster_name}_mgmt_nicconfig"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = azurerm_public_ip.mgmtIP[count.index].id
  }
}

resource "azurerm_network_interface_security_group_association" "mgmtSec" {
  count                     = var.instances["mgmt"]["count"]
  network_interface_id      = azurerm_network_interface.mgmtNIC[count.index].id
  network_security_group_id = azurerm_network_security_group.security_mgmt.id
}

resource "azurerm_network_interface" "nodeNIC" {
  for_each            = local.node
  name                = format("%s-%s-nic", var.cluster_name, each.key)
  location            = var.location
  resource_group_name = local.resource_group_name

  ip_configuration {
    name                          = format("%s-%s-ipconfig", var.cluster_name, each.key)
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = azurerm_public_ip.nodeIP[each.key].id
  }
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "login" {
  count                 = var.instances["login"]["count"]
  size                  = var.instances["login"]["type"]
  name                  = format("%s-login%d", var.cluster_name, count.index + 1)
  location              = var.location
  resource_group_name   = local.resource_group_name
  network_interface_ids = [azurerm_network_interface.loginNIC[count.index].id]

  os_disk {
    name              = "${var.cluster_name}_login${count.index + 1}_disk"
    caching           = "ReadWrite"
    storage_account_type = var.managed_disk_type
    disk_size_gb      = var.root_disk_size
  }

  source_image_reference {
    publisher = var.image["publisher"]
    offer     = var.image["offer"]
    sku       = var.image["sku"]
    version   = "latest"
  }

  computer_name  = format("login%d", count.index + 1)
  admin_username = "azure"
  custom_data = data.template_cloudinit_config.login_config[count.index].rendered


  disable_password_authentication = true
  dynamic "admin_ssh_key" {
    for_each = var.public_keys
    iterator = key
    content {
      username = "azure"
      public_key = key.value
    }

  }

  lifecycle {
    ignore_changes = [
      source_image_reference
    ]
  }
}

resource "azurerm_linux_virtual_machine" "mgmt" {
  count                 = var.instances["mgmt"]["count"]
  size               = var.instances["mgmt"]["type"]
  name                  = format("%s-mgmt%d", var.cluster_name, count.index + 1)
  location              = var.location
  resource_group_name   = local.resource_group_name
  network_interface_ids = [azurerm_network_interface.mgmtNIC[count.index].id]

  os_disk {
    name              = "${var.cluster_name}_mgmt${count.index + 1}_disk"
    caching           = "ReadWrite"
    storage_account_type = var.managed_disk_type
    disk_size_gb      = var.root_disk_size
  }

  source_image_reference {
    publisher = var.image["publisher"]
    offer     = var.image["offer"]
    sku       = var.image["sku"]
    version   = "latest"
  }

  computer_name  = format("mgmt%d", count.index + 1)
  admin_username = "azure"
  custom_data = data.template_cloudinit_config.mgmt_config[count.index].rendered
  
  disable_password_authentication = true
  dynamic "admin_ssh_key" {
    for_each = var.public_keys
    iterator = key
    content {
      username = "azure"
      public_key = key.value
    }
  }

  lifecycle {
    ignore_changes = [
      source_image_reference
    ]
  }
}

resource "azurerm_managed_disk" "home" {
  count                = lower(var.storage["type"]) == "nfs" ? 1 : 0
  name                 = "${var.cluster_name}_home"
  location             = var.location
  resource_group_name  = local.resource_group_name
  storage_account_type = var.managed_disk_type
  create_option        = "Empty"
  disk_size_gb         = var.storage["home_size"]
}

resource "azurerm_managed_disk" "project" {
  count                = lower(var.storage["type"]) == "nfs" ? 1 : 0
  name                 = "${var.cluster_name}_project"
  location             = var.location
  resource_group_name  = local.resource_group_name
  storage_account_type = var.managed_disk_type
  create_option        = "Empty"
  disk_size_gb         = var.storage["project_size"]
}

resource "azurerm_managed_disk" "scratch" {
  count                = lower(var.storage["type"]) == "nfs" ? 1 : 0
  name                 = "${var.cluster_name}_scratch"
  location             = var.location
  resource_group_name  = local.resource_group_name
  storage_account_type = var.managed_disk_type
  create_option        = "Empty"
  disk_size_gb         = var.storage["scratch_size"]
}

resource "azurerm_virtual_machine_data_disk_attachment" "home" {
  count              = (lower(var.storage["type"]) == "nfs" && var.instances["mgmt"]["count"] > 0) ? 1 : 0
  managed_disk_id    = azurerm_managed_disk.home[count.index].id
  virtual_machine_id = azurerm_linux_virtual_machine.mgmt[0].id
  lun                = count.index
  caching            = "ReadWrite"
}

resource "azurerm_virtual_machine_data_disk_attachment" "project" {
  count              = (lower(var.storage["type"]) == "nfs" && var.instances["mgmt"]["count"] > 0) ? 1 : 0
  managed_disk_id    = azurerm_managed_disk.project[count.index].id
  virtual_machine_id = azurerm_linux_virtual_machine.mgmt[0].id
  lun                = count.index + 10
  caching            = "ReadWrite"
}

resource "azurerm_virtual_machine_data_disk_attachment" "scratch" {
  count              = (lower(var.storage["type"]) == "nfs" && var.instances["mgmt"]["count"] > 0) ? 1 : 0
  managed_disk_id    = azurerm_managed_disk.scratch[count.index].id
  virtual_machine_id = azurerm_linux_virtual_machine.mgmt[0].id
  lun                = count.index + 20
  caching            = "ReadWrite"
}

locals {
  node_map = {
    for key in keys(local.node):
      key => merge(
        {
          name              = format("%s-%s", var.cluster_name, key),
          location          = var.location,
          image             = var.image,
          os_disk_name      = format("%s-%s-%s", var.cluster_name, key, "disk")
          managed_disk_type = var.managed_disk_type
          root_disk_size    = var.root_disk_size,
          user_data         = data.template_cloudinit_config.node_config[key].rendered,
          public_keys       = var.public_keys,
        },
        local.node[key]
    )
  }
}

resource "azurerm_linux_virtual_machine" "node" {
  for_each              = local.node_map
  name                  = each.value["name"]
  size                  = each.value["type"]
  location              = each.value["location"]
  resource_group_name   = local.resource_group_name
  network_interface_ids = [azurerm_network_interface.nodeNIC[each.key].id]

  source_image_reference {
    publisher = each.value["image"]["publisher"]
    offer     = each.value["image"]["offer"]
    sku       = each.value["image"]["sku"]
    version   = "latest"
  }

  os_disk {
    name              = each.value["os_disk_name"]
    caching           = "ReadWrite"
    storage_account_type = each.value["managed_disk_type"]
    disk_size_gb      = each.value["root_disk_size"]
  }

  computer_name  = each.key
  admin_username = "azure"
  custom_data = each.value["user_data"]

  disable_password_authentication = true
  dynamic "admin_ssh_key" {
    for_each = each.value["public_keys"]
    iterator = key
    content {
      username = "azure"
      public_key = key.value
    }
  }

  lifecycle {
    ignore_changes = [
      source_image_reference
    ]
  }
}

locals {
  resource_group_name = var.azure_resource_group == "" ? azurerm_resource_group.group[0].name : var.azure_resource_group
  mgmt1_ip        = try(azurerm_network_interface.mgmtNIC[0].private_ip_address, "")
  puppetmaster_ip = try(azurerm_network_interface.mgmtNIC[0].private_ip_address, "")
  puppetmaster_id = try(azurerm_linux_virtual_machine.mgmt[0].id, "")
  public_ip       = azurerm_public_ip.loginIP[*].ip_address
  login_ids       = azurerm_linux_virtual_machine.login[*].id
  cidr            = "10.0.1.0/24"
  home_dev        = [for vol in range(length(azurerm_managed_disk.home)):    "/dev/disk/azure/scsi1/lun${vol +  0}"]
  project_dev     = [for vol in range(length(azurerm_managed_disk.project)): "/dev/disk/azure/scsi1/lun${vol + 10}"]
  scratch_dev     = [for vol in range(length(azurerm_managed_disk.scratch)): "/dev/disk/azure/scsi1/lun${vol + 20}"]
}

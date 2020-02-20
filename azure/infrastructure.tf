# Configure the Microsoft Azure Provider
provider "azurerm" {
}

# Create a resource group
resource "azurerm_resource_group" "group" {
  name     = "myResourceGroup"
  location = var.location
}

# Create virtual network
resource "azurerm_virtual_network" "virtualNetwork" {
  name                = "myVnet"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.group.name
}

# Create subnet
resource "azurerm_subnet" "subnet" {
  name                 = "mySubnet"
  resource_group_name  = azurerm_resource_group.group.name
  virtual_network_name = azurerm_virtual_network.virtualNetwork.name
  address_prefix       = local.cidr
}

# Create public IPs
resource "azurerm_public_ip" "loginIP" {
  count                        = var.instances["login"]["count"]
  name                         = format("login-ip-%d", count.index + 1)
  location                     = var.location
  resource_group_name          = azurerm_resource_group.group.name
  allocation_method            = "Static"
}

resource "azurerm_public_ip" "mgmtIP" {
  count                        = var.instances["mgmt"]["count"]
  name                         = format("mgmt-ip-%d", count.index + 1)
  location                     = var.location
  resource_group_name          = azurerm_resource_group.group.name
  allocation_method            = "Dynamic"
}

resource "azurerm_public_ip" "nodeIP" {
  count                        = var.instances["node"]["count"]
  name                         = format("node-ip-%d", count.index + 1)
  location                     = var.location
  resource_group_name          = azurerm_resource_group.group.name
  allocation_method            = "Dynamic"
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "security_login" {
  name                = "myNetworkSecurityGroup"
  location            = var.location
  resource_group_name = azurerm_resource_group.group.name

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
  name                = "myNetworkSecurityGroup"
  location            = var.location
  resource_group_name = azurerm_resource_group.group.name

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
  name                      = format("login%d-nic", count.index + 1)
  location                  = var.location
  resource_group_name       = azurerm_resource_group.group.name
  network_security_group_id = azurerm_network_security_group.security_login.id

  ip_configuration {
    name                          = "loginNICConfig"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = azurerm_public_ip.loginIP[count.index].id
  }
}

resource "azurerm_network_interface" "mgmtNIC" {
  count                     = var.instances["mgmt"]["count"]
  name                      = format("mgmt%d-nic", count.index + 1)
  location                  = var.location
  resource_group_name       = azurerm_resource_group.group.name
  network_security_group_id = azurerm_network_security_group.security_mgmt.id

  ip_configuration {
    name                          = "mgmtNICConfig"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = azurerm_public_ip.mgmtIP[count.index].id
  }
}

resource "azurerm_network_interface" "nodeNIC" {
  count               = var.instances["node"]["count"]
  name                = format("node%d-nic", count.index + 1)
  location            = var.location
  resource_group_name = azurerm_resource_group.group.name

  ip_configuration {
    name                          = "nodeNICConfig"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = azurerm_public_ip.nodeIP[count.index].id
  }
}

# Create virtual machine
resource "azurerm_virtual_machine" "login" {
  count                 = var.instances["login"]["count"]
  vm_size               = var.instances["login"]["type"]
  name                  = format("login%d", count.index + 1)
  location              = var.location
  resource_group_name   = azurerm_resource_group.group.name
  network_interface_ids = [azurerm_network_interface.loginNIC[count.index].id]

  storage_os_disk {
    name              = "loginDisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = var.managed_disk_type
    disk_size_gb      = var.root_disk_size
  }

  storage_image_reference {
    publisher = var.image["publisher"]
    offer     = var.image["offer"]
    sku       = var.image["sku"]
    version   = "latest"
  }

  os_profile {
    computer_name  = format("login%d", count.index + 1)
    admin_username = "azure"
    custom_data = data.template_cloudinit_config.login_config[count.index].rendered
  }

  os_profile_linux_config {
    disable_password_authentication = true
    dynamic "ssh_keys" {
      for_each = var.public_keys
      iterator = key
      content {
        key_data = key.value
        path     = "/home/azure/.ssh/authorized_keys"
      }
    }
  }

  lifecycle {
    ignore_changes = [
      storage_image_reference
    ]
  }
}

resource "azurerm_virtual_machine" "mgmt" {
  count                 = var.instances["mgmt"]["count"]
  vm_size               = var.instances["mgmt"]["type"]
  name                  = format("mgmt%d", count.index + 1)
  location              = var.location
  resource_group_name   = azurerm_resource_group.group.name
  network_interface_ids = [azurerm_network_interface.mgmtNIC[count.index].id]

  storage_os_disk {
    name              = "mgmtDisk${count.index + 1}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = var.managed_disk_type
    disk_size_gb      = var.root_disk_size
  }

  storage_image_reference {
    publisher = var.image["publisher"]
    offer     = var.image["offer"]
    sku       = var.image["sku"]
    version   = "latest"
  }

  os_profile {
    computer_name  = format("mgmt%d", count.index + 1)
    admin_username = "azure"
    custom_data = data.template_cloudinit_config.mgmt_config[count.index].rendered
  }

  os_profile_linux_config {
    disable_password_authentication = true
    dynamic "ssh_keys" {
      for_each = var.public_keys
      iterator = key
      content {
        key_data = key.value
        path     = "/home/azure/.ssh/authorized_keys"
      }
    }
  }

  lifecycle {
    ignore_changes = [
      storage_image_reference
    ]
  }
}

resource "azurerm_managed_disk" "home" {
  count                = lower(var.storage["type"]) == "nfs" ? 1 : 0
  name                 = "home"
  location             = var.location
  resource_group_name  = azurerm_resource_group.group.name
  storage_account_type = var.managed_disk_type
  create_option        = "Empty"
  disk_size_gb         = var.storage["home_size"]
}

resource "azurerm_managed_disk" "project" {
  count                = lower(var.storage["type"]) == "nfs" ? 1 : 0
  name                 = "project"
  location             = var.location
  resource_group_name  = azurerm_resource_group.group.name
  storage_account_type = var.managed_disk_type
  create_option        = "Empty"
  disk_size_gb         = var.storage["project_size"]
}

resource "azurerm_managed_disk" "scratch" {
  count                = lower(var.storage["type"]) == "nfs" ? 1 : 0
  name                 = "scratch"
  location             = var.location
  resource_group_name  = azurerm_resource_group.group.name
  storage_account_type = var.managed_disk_type
  create_option        = "Empty"
  disk_size_gb         = var.storage["scratch_size"]
}

resource "azurerm_virtual_machine_data_disk_attachment" "home" {
  count              = (lower(var.storage["type"]) == "nfs" && var.instances["mgmt"]["count"] > 0) ? 1 : 0
  managed_disk_id    = azurerm_managed_disk.home[0].id
  virtual_machine_id = azurerm_virtual_machine.mgmt[0].id
  lun                = "10"
  caching            = "ReadWrite"
}

resource "azurerm_virtual_machine_data_disk_attachment" "project" {
  count              = (lower(var.storage["type"]) == "nfs" && var.instances["mgmt"]["count"] > 0) ? 1 : 0
  managed_disk_id    = azurerm_managed_disk.project[0].id
  virtual_machine_id = azurerm_virtual_machine.mgmt[0].id
  lun                = "11"
  caching            = "ReadWrite"
}

resource "azurerm_virtual_machine_data_disk_attachment" "scratch" {
  count              = (lower(var.storage["type"]) == "nfs" && var.instances["mgmt"]["count"] > 0) ? 1 : 0
  managed_disk_id    = azurerm_managed_disk.scratch[0].id
  virtual_machine_id = azurerm_virtual_machine.mgmt[0].id
  lun                = "12"
  caching            = "ReadWrite"
}

resource "azurerm_virtual_machine" "nodevm" {
  name                  = "node${count.index + 1}"
  count                 = var.instances["node"]["count"]
  vm_size               = var.instances["node"]["type"]
  location              = var.location
  resource_group_name   = azurerm_resource_group.group.name
  network_interface_ids = [azurerm_network_interface.nodeNIC[count.index].id]

  storage_os_disk {
    name              = "nodeDisk${count.index + 1}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = var.managed_disk_type
    disk_size_gb      = var.root_disk_size
  }

  storage_image_reference {
    publisher = var.image["publisher"]
    offer     = var.image["offer"]
    sku       = var.image["sku"]
    version   = "latest"
  }

  os_profile {
    computer_name  = "node${count.index + 1}"
    admin_username = "azure"
    custom_data = data.template_cloudinit_config.node_config[count.index].rendered
  }

  os_profile_linux_config {
    disable_password_authentication = true
    dynamic "ssh_keys" {
      for_each = var.public_keys
      iterator = key
      content {
        key_data = key.value
        path     = "/home/azure/.ssh/authorized_keys"
      }
    }
  }

  lifecycle {
    ignore_changes = [
      storage_image_reference
    ]
  }
}

locals {
  mgmt1_ip   = azurerm_network_interface.mgmtNIC[0].private_ip_address
  public_ip   = azurerm_public_ip.loginIP[0].ip_address
  cidr        = "10.0.1.0/24"
  home_dev    = "/dev/disk/azure/scsi1/lun10"
  project_dev = "/dev/disk/azure/scsi1/lun11"
  scratch_dev = "/dev/disk/azure/scsi1/lun12"
}

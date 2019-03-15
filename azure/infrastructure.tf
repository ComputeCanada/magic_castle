# Configure the Microsoft Azure Provider
provider "azurerm" {
}

variable "ssh_user" {
  default = "centos"
}

# Create a resource group
resource "azurerm_resource_group" "group" {
  name     = "myResourceGroup"
  location = "${var.location}"
}

# Create virtual network
resource "azurerm_virtual_network" "virtualNetwork" {
  name                = "myVnet"
  address_space       = ["10.0.0.0/16"]
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.group.name}"
}

# Create subnet
resource "azurerm_subnet" "subnet" {
  name                 = "mySubnet"
  resource_group_name  = "${azurerm_resource_group.group.name}"
  virtual_network_name = "${azurerm_virtual_network.virtualNetwork.name}"
  address_prefix       = "${local.cidr}"
}

# Create public IPs
resource "azurerm_public_ip" "loginIP" {
  name                         = "loginIP"
  location                     = "${var.location}"
  resource_group_name          = "${azurerm_resource_group.group.name}"
  public_ip_address_allocation = "static"
}

resource "azurerm_public_ip" "mgmtIP" {
  name                         = "mgmtIP"
  location                     = "${var.location}"
  resource_group_name          = "${azurerm_resource_group.group.name}"
  public_ip_address_allocation = "dynamic"
}

resource "azurerm_public_ip" "nodeIP" {
  name                         = "nodeIP${count.index + 1}"
  count                        = "${var.nb_nodes}"
  location                     = "${var.location}"
  resource_group_name          = "${azurerm_resource_group.group.name}"
  public_ip_address_allocation = "dynamic"
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "security_login" {
  name                = "myNetworkSecurityGroup"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.group.name}"

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

  security_rule {
    name                       = "HTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTPS"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "security_mgmt" {
  name                = "myNetworkSecurityGroup"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.group.name}"

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
  name                      = "loginNIC"
  location                  = "${var.location}"
  resource_group_name       = "${azurerm_resource_group.group.name}"
  network_security_group_id = "${azurerm_network_security_group.security_login.id}"

  ip_configuration {
    name                          = "loginNICConfig"
    subnet_id                     = "${azurerm_subnet.subnet.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${azurerm_public_ip.loginIP.id}"
  }
}

resource "azurerm_network_interface" "mgmtNIC" {
  name                      = "mgmtNIC"
  location                  = "${var.location}"
  resource_group_name       = "${azurerm_resource_group.group.name}"
  network_security_group_id = "${azurerm_network_security_group.security_mgmt.id}"

  ip_configuration {
    name                          = "mgmtNICConfig"
    subnet_id                     = "${azurerm_subnet.subnet.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${azurerm_public_ip.mgmtIP.id}"
  }
}

resource "azurerm_network_interface" "nodeNIC" {
  name                      = "nodeNIC${count.index + 1}"
  count                     = "${var.nb_nodes}"
  location                  = "${var.location}"
  resource_group_name       = "${azurerm_resource_group.group.name}"

  ip_configuration {
    name                          = "nodeNICConfig"
    subnet_id                     = "${azurerm_subnet.subnet.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${element(azurerm_public_ip.nodeIP.*.id, count.index)}"
  }
}

# Create virtual machine
resource "azurerm_virtual_machine" "login01vm" {
  name                  = "login01"
  location              = "${var.location}"
  resource_group_name   = "${azurerm_resource_group.group.name}"
  network_interface_ids = ["${azurerm_network_interface.loginNIC.id}"]
  vm_size               = "${var.vm_size_login}"

  storage_os_disk {
    name              = "loginDisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "${var.managed_disk_type}"
  }

  storage_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "7-CI"
    version   = "latest"
  }

  os_profile {
    computer_name  = "${var.cluster_name}01"
    admin_username = "${var.ssh_user}"
    custom_data = "${data.template_cloudinit_config.login_config.rendered}"
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path     = "/home/${var.ssh_user}/.ssh/authorized_keys"
      key_data = "${file(var.public_key_path)}"
    }
  }
}

resource "azurerm_virtual_machine" "mgmt01vm" {
  name                  = "mgmt01"
  location              = "${var.location}"
  resource_group_name   = "${azurerm_resource_group.group.name}"
  network_interface_ids = ["${azurerm_network_interface.mgmtNIC.id}"]
  vm_size               = "${var.vm_size_mgmt}"

  storage_os_disk {
    name              = "mgmtDisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "${var.managed_disk_type}"
    disk_size_gb      = "${var.shared_storage_size}"
  }

  storage_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "7-CI"
    version   = "latest"
  }

  os_profile {
    computer_name  = "mgmt01"
    admin_username = "${var.ssh_user}"
    custom_data = "${data.template_cloudinit_config.mgmt_config.rendered}"
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path     = "/home/${var.ssh_user}/.ssh/authorized_keys"
      key_data = "${file(var.public_key_path)}"
    }
  }
}

resource "azurerm_managed_disk" "home" {
  name                 = "home"
  location             = "${var.location}"
  resource_group_name  = "${azurerm_resource_group.group.name}"
  storage_account_type = "${var.managed_disk_type}"
  create_option        = "Empty"
  disk_size_gb         = "${var.home_size}"
}

resource "azurerm_managed_disk" "project" {
  name                 = "project"
  location             = "${var.location}"
  resource_group_name  = "${azurerm_resource_group.group.name}"
  storage_account_type = "${var.managed_disk_type}"
  create_option        = "Empty"
  disk_size_gb         = "${var.project_size}"
}

resource "azurerm_managed_disk" "scratch" {
  name                 = "scratch"
  location             = "${var.location}"
  resource_group_name  = "${azurerm_resource_group.group.name}"
  storage_account_type = "${var.managed_disk_type}"
  create_option        = "Empty"
  disk_size_gb         = "${var.scratch_size}"
}

resource "azurerm_virtual_machine_data_disk_attachment" "home" {
  managed_disk_id    = "${azurerm_managed_disk.home.id}"
  virtual_machine_id = "${azurerm_virtual_machine.mgmt01vm.id}"
  lun                = "10"
  caching            = "ReadWrite"
}

resource "azurerm_virtual_machine_data_disk_attachment" "project" {
  managed_disk_id    = "${azurerm_managed_disk.project.id}"
  virtual_machine_id = "${azurerm_virtual_machine.mgmt01vm.id}"
  lun                = "11"
  caching            = "ReadWrite"
}

resource "azurerm_virtual_machine_data_disk_attachment" "scratch" {
  managed_disk_id    = "${azurerm_managed_disk.scratch.id}"
  virtual_machine_id = "${azurerm_virtual_machine.mgmt01vm.id}"
  lun                = "12"
  caching            = "ReadWrite"
}

resource "azurerm_virtual_machine" "nodevm" {
  name                  = "node${count.index + 1}"
  count                 = "${var.nb_nodes}"
  location              = "${var.location}"
  resource_group_name   = "${azurerm_resource_group.group.name}"
  network_interface_ids = ["${element(azurerm_network_interface.nodeNIC.*.id, count.index)}"]
  vm_size               = "${var.vm_size_node}"

  storage_os_disk {
    name              = "nodeDisk${count.index + 1}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "${var.managed_disk_type}"
  }

  storage_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "7-CI"
    version   = "latest"
  }

  os_profile {
    computer_name  = "node${count.index + 1}"
    admin_username = "${var.ssh_user}"
    custom_data  = "${element(data.template_cloudinit_config.node_config.*.rendered, count.index)}"

  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path     = "/home/${var.ssh_user}/.ssh/authorized_keys"
      key_data = "${file(var.public_key_path)}"
    }
  }
}

locals {
  mgmt01_ip = "${azurerm_network_interface.mgmtNIC.private_ip_address}"
  public_ip = "${azurerm_public_ip.loginIP.ip_address}"
  cidr = "10.0.1.0/24"
  home_dev = "/dev/disk/azure/scsi1/lun${azurerm_virtual_machine_data_disk_attachment.home.lun}"
  project_dev = "/dev/disk/azure/scsi1/lun${azurerm_virtual_machine_data_disk_attachment.project.lun}"
  scratch_dev = "/dev/disk/azure/scsi1/lun${azurerm_virtual_machine_data_disk_attachment.scratch.lun}"
}


# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

module "design" {
  source       = "../common/design"
  cluster_name = var.cluster_name
  domain       = var.domain
  instances    = var.instances
  volumes      = var.volumes
}

module "instance_config" {
  source           = "../common/instance_config"
  host_prefixes    = toset(keys(var.instances))
  instances        = module.design.instances
  config_git_url   = var.config_git_url
  config_version   = var.config_version
  puppetserver_ip  = local.puppetserver_ip
  sudoer_username  = var.sudoer_username
  public_keys      = var.public_keys
  host2prefix      = module.design.host2prefix
  generate_ssh_key = var.generate_ssh_key
}

module "cluster_config" {
  source          = "../common/cluster_config"
  instances       = local.all_instances
  nb_users        = var.nb_users
  hieradata       = var.hieradata
  software_stack  = var.software_stack
  cloud_provider  = local.cloud_provider
  cloud_region    = local.cloud_region
  sudoer_username = var.sudoer_username
  guest_passwd    = var.guest_passwd
  all_tags        = module.design.all_tags
  public_ip       = local.public_ip
  domain_name     = module.design.domain_name
  cluster_name    = var.cluster_name
  puppetserver_id = local.puppetserver_id
  volume_devices  = local.volume_devices
  private_ssh_key = module.instance_config.private_key
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

# Create virtual machine
resource "azurerm_linux_virtual_machine" "instances" {
  for_each              = module.design.instances
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
  custom_data    = base64gzip(module.instance_config.user_data[each.key])

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

resource "azurerm_managed_disk" "volumes" {
  for_each             = module.design.volumes
  name                 = format("%s-%s", var.cluster_name, each.key)
  location             = var.location
  resource_group_name  = local.resource_group_name
  storage_account_type = lookup(each.value, "type", var.managed_disk_type)
  create_option        = "Empty"
  disk_size_gb         = each.value.size
}

resource "azurerm_virtual_machine_data_disk_attachment" "attachments" {
  for_each           = module.design.volumes
  managed_disk_id    = azurerm_managed_disk.volumes[each.key].id
  virtual_machine_id = azurerm_linux_virtual_machine.instances[each.value.instance].id
  lun                = index(local.volume_per_instance[each.value.instance], replace(each.key, "${each.value.instance}-", ""))
  caching            = "ReadWrite"
}

locals {
  volume_devices = {
    for ki, vi in var.volumes :
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

  puppetserver_id = try(element([for x, values in module.design.instances : azurerm_linux_virtual_machine.instances[x].id if contains(values.tags, "puppet")], 0), "")
  all_instances = { for x, values in module.design.instances :
    x => {
      public_ip = azurerm_public_ip.public_ip[x].ip_address
      local_ip  = azurerm_network_interface.nic[x].private_ip_address
      tags      = values["tags"]
      id        = azurerm_linux_virtual_machine.instances[x].id
      hostkeys = {
        rsa = module.instance_config.rsa_hostkeys[x]
      }
    }
  }
}

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
  instances        = module.design.instances
  config_git_url   = var.config_git_url
  config_version   = var.config_version
  puppetserver_ip  = local.puppetserver_ip
  sudoer_username  = var.sudoer_username
  public_keys      = var.public_keys
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
  public_keys     = var.public_keys
  guest_passwd    = var.guest_passwd
  domain_name     = module.design.domain_name
  cluster_name    = var.cluster_name
  volume_devices  = local.volume_devices
  tf_ssh_key      = module.instance_config.ssh_key
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

locals {
  to_build_instances = {
    for key, values in module.design.instances: key => values
    if ! contains(values.tags, "draft") || contains(var.draft_exclusion, key)
   }
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "instances" {
  for_each              = local.to_build_instances
  size                  = each.value.type
  name                  = format("%s-%s", var.cluster_name, each.key)
  location              = var.location
  resource_group_name   = local.resource_group_name
  network_interface_ids = [azurerm_network_interface.nic[each.key].id]

  os_disk {
    name                 = format("%s-%s-disk", var.cluster_name, each.key)
    caching              = "ReadWrite"
    storage_account_type = lookup(each.value, "disk_type", "Premium_LRS")
    disk_size_gb         = lookup(each.value, "disk_size", 30)
  }

  dynamic "plan" {
    for_each = var.plan["name"] != null ? [var.plan] : []
    iterator = plan
    content {
      name      = plan.value["name"]
      product   = plan.value["product"]
      publisher = plan.value["publisher"]
    }
  }

  dynamic "source_image_reference" {
    for_each = can(tomap(lookup(each.value, "image", var.image))) ? [lookup(each.value, "image", var.image)] : []
    iterator = key
    content {
      publisher = key.value["publisher"]
      offer     = key.value["offer"]
      sku       = key.value["sku"]
      version   = lookup(key.value, "version", "latest")
    }
  }
  source_image_id = can(tomap(lookup(each.value, "image", var.image))) ? null : tostring(lookup(each.value, "image", var.image))

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

  priority = contains(each.value["tags"], "spot") ? "Spot" : "Regular"
  # Spot instances specifics
  max_bid_price   = contains(each.value["tags"], "spot") ? lookup(each.value, "max_bid_price", null) : null
  eviction_policy = contains(each.value["tags"], "spot") ? lookup(each.value, "eviction_policy", "Deallocate") : null

  lifecycle {
    ignore_changes = [
      source_image_reference,
      source_image_id,
      custom_data,
    ]
  }
}

resource "azurerm_managed_disk" "volumes" {
  for_each             = module.design.volumes
  name                 = format("%s-%s", var.cluster_name, each.key)
  location             = var.location
  resource_group_name  = local.resource_group_name
  storage_account_type = lookup(each.value, "type", "Premium_LRS")
  create_option        = "Empty"
  disk_size_gb         = each.value.size
}

resource "azurerm_virtual_machine_data_disk_attachment" "attachments" {
  for_each           = module.design.volumes
  managed_disk_id    = azurerm_managed_disk.volumes[each.key].id
  virtual_machine_id = azurerm_linux_virtual_machine.instances[each.value.instance].id
  lun                = index(module.design.volume_per_instance[each.value.instance], replace(each.key, "${each.value.instance}-", ""))
  caching            = "ReadWrite"
}

locals {
  volume_devices = {
    for ki, vi in var.volumes :
    ki => {
      for kj, vj in vi :
      kj => [for key, volume in module.design.volumes :
        "/dev/disk/azure/scsi1/lun${index(module.design.volume_per_instance[volume.instance], replace(key, "${volume.instance}-", ""))}"
        if key == "${volume["instance"]}-${ki}-${kj}"
      ]
    }
  }
}

locals {
  resource_group_name = var.azure_resource_group == "" ? azurerm_resource_group.group[0].name : var.azure_resource_group

  vmsizes = jsondecode(file("${path.module}/vmsizes.json"))
  all_instances = { for x, values in module.design.instances :
    x => {
      public_ip = azurerm_public_ip.public_ip[x].ip_address
      local_ip  = azurerm_network_interface.nic[x].private_ip_address
      tags      = values["tags"]
      id        = try(azurerm_linux_virtual_machine.instances[x].id, "")
      hostkeys  = {
        rsa = module.instance_config.rsa_hostkeys[x]
        ed25519 = module.instance_config.ed25519_hostkeys[x]
      }
      specs = {
        cpus = local.vmsizes[values["type"]]["vcpus"]
        ram  = local.vmsizes[values["type"]]["ram"]
        gpu  = local.vmsizes[values["type"]]["gpus"]
      }
    }
  }
}

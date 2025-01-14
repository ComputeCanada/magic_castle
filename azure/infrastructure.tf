# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

module "design" {
  source         = "../common/design"
  cluster_name   = var.cluster_name
  domain         = var.domain
  instances      = var.instances
  min_disk_size  = 30
  pool           = var.pool
  volumes        = var.volumes
  firewall_rules = var.firewall_rules
}

module "configuration" {
  source                = "../common/configuration"
  inventory             = local.inventory
  config_git_url        = var.config_git_url
  config_version        = var.config_version
  sudoer_username       = var.sudoer_username
  public_keys           = var.public_keys
  domain_name           = module.design.domain_name
  bastion_tag           = module.design.bastion_tag
  cluster_name          = var.cluster_name
  guest_passwd          = var.guest_passwd
  nb_users              = var.nb_users
  software_stack        = var.software_stack
  cloud_provider        = local.cloud_provider
  cloud_region          = local.cloud_region
  skip_upgrade          = var.skip_upgrade
  puppetfile            = var.puppetfile
}

module "provision" {
  source          = "../common/provision"
  bastions        = module.configuration.bastions
  puppetservers   = module.configuration.puppetservers
  tf_ssh_key      = module.configuration.ssh_key
  terraform_data  = module.configuration.terraform_data
  terraform_facts = module.configuration.terraform_facts
  hieradata       = var.hieradata
  hieradata_dir   = var.hieradata_dir
  eyaml_key       = var.eyaml_key
  puppetfile      = var.puppetfile
  depends_on      = [ azurerm_linux_virtual_machine.instances ]
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
  for_each              = module.design.instances_to_build
  size                  = each.value.type
  name                  = format("%s-%s", var.cluster_name, each.key)
  location              = var.location
  resource_group_name   = local.resource_group_name
  network_interface_ids = [azurerm_network_interface.nic[each.key].id]

  os_disk {
    name                 = format("%s-%s-disk", var.cluster_name, each.key)
    caching              = "ReadWrite"
    storage_account_type = lookup(each.value, "disk_type", "Premium_LRS")
    disk_size_gb         = each.value.disk_size
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
  custom_data    = base64gzip(module.configuration.user_data[each.key])

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
      admin_ssh_key,
    ]
  }
}

resource "azurerm_managed_disk" "volumes" {
  for_each             = {
    for x, values in module.design.volumes : x => values if lookup(values, "managed", true)
  }
  name                 = format("%s-%s", var.cluster_name, each.key)
  location             = var.location
  resource_group_name  = local.resource_group_name
  storage_account_type = lookup(each.value, "type", "Premium_LRS")
  create_option        = "Empty"
  disk_size_gb         = each.value.size
}
data "azurerm_managed_disk" "existing_volumes" {
  for_each             = {
    for x, values in module.design.volumes : x => values if ! lookup(values, "managed", true)
  }
  name                 = format("%s-%s", var.cluster_name, each.key)
  resource_group_name  = local.resource_group_name
}

resource "azurerm_virtual_machine_data_disk_attachment" "attachments" {
  for_each           = module.design.volumes
  managed_disk_id    = try(azurerm_managed_disk.volumes[each.key].id, data.azurerm_managed_disk.existing_volumes[each.key].id)
  virtual_machine_id = azurerm_linux_virtual_machine.instances[each.value.instance].id
  lun                = index(module.design.volume_per_instance[each.value.instance], replace(each.key, "${each.value.instance}-", ""))
  caching            = "ReadWrite"
}

locals {
  resource_group_name = var.azure_resource_group == "" ? azurerm_resource_group.group[0].name : var.azure_resource_group

  vmsizes   = jsondecode(file("${path.module}/vmsizes.json"))
  inventory = { for x, values in module.design.instances :
    x => {
      public_ip = azurerm_public_ip.public_ip[x].ip_address
      local_ip  = azurerm_network_interface.nic[x].private_ip_address
      prefix    = values.prefix
      tags      = values.tags
      specs = merge({
        cpus   = local.vmsizes[values.type].vcpus
        ram    = local.vmsizes[values.type].ram
        gpus   = local.vmsizes[values.type].gpus
      }, values.specs)
      volumes = contains(keys(module.design.volume_per_instance), x) ? {
        for pv_key, pv_values in var.volumes:
          pv_key => {
            for name, specs in pv_values:
              name => merge(
                { glob = "/dev/disk/azure/scsi1/lun${index(module.design.volume_per_instance[x], "${pv_key}-${name}")}" },
                specs,
              )
          } if contains(values.tags, pv_key)
       } : {}
    }
  }

  public_instances = { for host in keys(module.design.instances_to_build):
    host => merge(module.configuration.inventory[host], {id=try(azurerm_linux_virtual_machine.instances[host].id, "")})
    if contains(module.configuration.inventory[host].tags, "public")
  }
}

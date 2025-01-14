# Configure the AWS Provider
provider "aws" {
  region = var.region
}

module "design" {
  source         = "../common/design"
  cluster_name   = var.cluster_name
  domain         = var.domain
  instances      = var.instances
  min_disk_size  = 20
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
  depends_on      = [aws_instance.instances, aws_eip.public_ip]
}

data "aws_availability_zones" "available" {
  state = "available"
  lifecycle {
    postcondition {
      condition = var.availability_zone == "" || contains(self.names, var.availability_zone)
      error_message = "var.availability_zone must be one of ${jsonencode(self.names)}"
    }
  }
}

# Retrieve the availability zones in which each unique instance type is available
data "aws_ec2_instance_type_offerings" "inst_az" {
  filter {
    name   = "instance-type"
    values = distinct([for instance in module.design.instances: instance.type])
  }
  location_type = "availability-zone"
}

# Build a set of availability zones that offer all selected instance types
locals {
  instance_types = distinct([for instance in module.design.instances: instance.type])
  az_choices = setintersection(data.aws_availability_zones.available.names, values({
    for type in local.instance_types: type =>
      [ for idx, zone in data.aws_ec2_instance_type_offerings.inst_az.locations: zone
        if data.aws_ec2_instance_type_offerings.inst_az.instance_types[idx] == type
      ]
  })...)
}

resource "terraform_data" "az_check" {
  lifecycle {
    precondition {
      condition = length(local.az_choices) > 0
      error_message = "There is not a single availability zone in ${var.region} that provides all instance types you have selected."
    }
    precondition {
      condition = var.availability_zone == "" || contains(local.az_choices, var.availability_zone)
      error_message = <<EOT
      The selected availability zone "${var.availability_zone}" does not provide all instance types you have selected.
Pick one of these zone instead ${jsonencode(local.az_choices)} or leave var.availability_zone undefined."
EOT
    }
  }
}

resource "random_shuffle" "random_az" {
  count = var.availability_zone == "" ? 1 : 0
  input = local.az_choices
  result_count = 1
}

locals {
  availability_zone = var.availability_zone != "" ? var.availability_zone : random_shuffle.random_az[0].result[0]
}

resource "aws_placement_group" "efa_group" {
  name     = "${var.cluster_name}-efa-placement_group"
  strategy = "cluster"
}

data "aws_ec2_instance_type" "instance_type" {
  for_each      = var.instances
  instance_type = each.value.type
  lifecycle {
    precondition {
      condition = contains(data.aws_ec2_instance_type_offerings.inst_az.instance_types, each.value.type)
      error_message = "The selected region ${var.region} does not offer ${each.value.type} instances."
    }
  }
}

resource "aws_instance" "instances" {
  for_each          = module.design.instances_to_build
  instance_type     = each.value.type
  ami               = lookup(each.value, "image", var.image)
  user_data         = base64gzip(module.configuration.user_data[each.key])
  availability_zone = local.availability_zone
  placement_group   = contains(each.value.tags, "efa") ? aws_placement_group.efa_group.id : null

  network_interface {
    network_interface_id = aws_network_interface.nic[each.key].id
    device_index         = 0
  }

  ebs_optimized = true
  root_block_device {
    volume_type = lookup(each.value, "disk_type", "gp2")
    volume_size = each.value.disk_size
  }

  tags = {
    Name = format("%s-%s", var.cluster_name, each.key)
  }

  lifecycle {
    ignore_changes = [
      ami,
      user_data,
    ]
  }

  dynamic "instance_market_options" {
    for_each = contains(each.value.tags, "spot") ? [each.value] : []
    iterator = spot
    content {
      market_type = "spot"
      spot_options {
        spot_instance_type             = lookup(spot, "spot_instance_type", "persistent")
        instance_interruption_behavior = lookup(spot, "instance_interruption_behavior", "stop")
        max_price                      = lookup(spot, "max_price", null)
      }
    }
  }

  depends_on = [aws_internet_gateway.gw]
}

resource "aws_ebs_volume" "volumes" {
  for_each          = {
    for x, values in module.design.volumes : x => values if lookup(values, "managed", true)
  }
  availability_zone = local.availability_zone
  size              = each.value.size
  type              = lookup(each.value, "type", null)
  snapshot_id       = lookup(each.value, "snapshot", null)

  tags = {
    Name = "${var.cluster_name}-${each.key}"
  }
}
data "aws_ebs_volume" "existing_volumes" {
  for_each = {
    for x, values in module.design.volumes : x => values if ! lookup(values, "managed", true)
  }

  filter {
    name   = "tag:Name"
    values = ["${var.cluster_name}-${each.key}"]
  }
}

locals {
  device_names = [
    "/dev/sdf", "/dev/sdg", "/dev/sdh", "/dev/sdi", "/dev/sdj",
    "/dev/sdk", "/dev/sdl", "/dev/sdm", "/dev/sdn", "/dev/sdp"
  ]
}

resource "aws_volume_attachment" "attachments" {
  for_each     = module.design.volumes
  device_name  = local.device_names[index(module.design.volume_per_instance[each.value.instance], replace(each.key, "${each.value.instance}-", ""))]
  volume_id    = try(aws_ebs_volume.volumes[each.key].id, data.aws_ebs_volume.existing_volumes[each.key].id)
  instance_id  = aws_instance.instances[each.value.instance].id
  skip_destroy = true
}

locals {
  inventory = { for x, values in module.design.instances :
    x => {
      public_ip   = contains(values.tags, "public") ? aws_eip.public_ip[x].public_ip : ""
      local_ip    = aws_network_interface.nic[x].private_ip
      prefix      = values.prefix
      tags        = values.tags
      specs = merge({
        cpus   = data.aws_ec2_instance_type.instance_type[values.prefix].default_vcpus
        ram    = data.aws_ec2_instance_type.instance_type[values.prefix].memory_size
        gpus   = try(one(data.aws_ec2_instance_type.instance_type[values.prefix].gpus).count, 0)
      }, values.specs)
      volumes = contains(keys(module.design.volume_per_instance), x) ? {
        for pv_key, pv_values in var.volumes:
          pv_key => {
            for name, specs in pv_values:
              name => merge(
                { glob = try("/dev/disk/by-id/*${replace(aws_ebs_volume.volumes["${x}-${pv_key}-${name}"].id, "-", "")}", "/dev/disk/by-id/*${replace(data.aws_ebs_volume.existing_volumes["${x}-${pv_key}-${name}"].id, "-", "")}") },
                specs,
              )
          } if contains(values.tags, pv_key)
       } : {}
    }
  }

  public_instances = { for host in keys(module.design.instances_to_build):
    host => merge(module.configuration.inventory[host], {id=try(aws_instance.instances[host].id, "")})
    if contains(module.configuration.inventory[host].tags, "public")
  }
}

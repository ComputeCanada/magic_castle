output "instances" {
  value = local.instances
}

output "instances_to_build" {
  value = local.instances_to_build
}

output "volumes" {
  value = local.volumes
}

output "volume_per_instance" {
  value = local.volume_per_instance
}

output "domain_name" {
  value = local.domain_name
}

output "bastion_tag" {
  value = local.bastion_tag
}

output "all_instance_tags" {
  value = toset(flatten([for instance in local.instances: instance.tags]))
}
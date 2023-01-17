variable "name" {
}

variable "vhosts" {
    type    = list(string)
    default = ["ipa", "jupyter", "mokey", "explore"]
}

variable "public_instances" {}

variable "domain_tag" {}
variable "vhost_tag" {}

data "external" "key2fp" {
  for_each = var.public_instances
  program = ["bash", "${path.module}/key2fp.sh"]
  query = {
    rsa = each.value["hostkeys"]["rsa"]
    ed25519 = each.value["hostkeys"]["ed25519"]
  }
}

locals {
    records = concat(
    [
        for key, values in var.public_instances: {
            type = "A"
            name = join(".", [key, var.name])
            value = values["public_ip"]
            data = null
        }
    ],
    flatten([
        for key, values in var.public_instances: [
            for vhost in var.vhosts:
            {
                type  = "A"
                name  = join(".", [vhost, var.name])
                value = values["public_ip"]
                data  = null
            }
        ]
        if contains(values["tags"], var.vhost_tag)
    ]),
    [
        for key, values in var.public_instances: {
            type  = "A"
            name  = var.name
            value = values["public_ip"]
            data  = null
        }
        if contains(values["tags"], var.domain_tag)
    ],
    [
        for key, values in var.public_instances: {
            type  = "SSHFP"
            name  = join(".", [key, var.name])
            value = null
            data  = {
                algorithm   = data.external.key2fp[key].result["rsa_algorithm"]
                type        = 2
                fingerprint = data.external.key2fp[key].result["rsa_sha256"]
            }
        }
    ],
    [
        for key, values in var.public_instances: {
            type  = "SSHFP"
            name  = join(".", [key, var.name])
            value = null
            data  = {
                algorithm   = data.external.key2fp[key].result["ed25519_algorithm"]
                type        = 2
                fingerprint = data.external.key2fp[key].result["ed25519_sha256"]
            }
        }
    ],
    [
         {
            type  = "SSHFP"
            name  = var.name
            value = null
            data  = {
                algorithm   = try(coalesce([for key, values in var.public_instances: data.external.key2fp[key].result["rsa_algorithm"] if contains(values["tags"], var.domain_tag)]...), 0)
                type        = 2
                fingerprint = try(coalesce([for key, values in var.public_instances: data.external.key2fp[key].result["rsa_sha256"] if contains(values["tags"], var.domain_tag)]...), 0)
            }
        }
    ],
    [
         {
            type  = "SSHFP"
            name  = var.name
            value = null
            data  = {
                algorithm   = try(coalesce([for key, values in var.public_instances: data.external.key2fp[key].result["ed25519_algorithm"] if contains(values["tags"], var.domain_tag)]...), 0)
                type        = 2
                fingerprint = try(coalesce([for key, values in var.public_instances: data.external.key2fp[key].result["ed25519_sha256"] if contains(values["tags"], var.domain_tag)]...), 0)
            }
        }
    ])
}

output "records" {
    value = local.records
}
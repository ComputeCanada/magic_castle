variable "name" {
}

variable "vhosts" {
}

variable "public_instances" {}

variable "domain_tag" {}
variable "vhost_tag" {}

data "external" "key2fp" {
  for_each = var.public_instances
  program = ["bash", "${path.module}/key2fp.sh"]
  query = each.value["hostkeys"]
}

locals {
    # Refer to
    # https://www.iana.org/assignments/dns-sshfp-rr-parameters/dns-sshfp-rr-parameters.xhtml
    SSHFP_SPEC = {
        "ssh-rsa"       = "1"
        "ssh-dss"       = "2"
        "ssh-ecdsa"     = "3"
        "ssh-ed25519"   = "4"
    }

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
    flatten([
        for key, values in var.public_instances: [
            for alg in keys(values["hostkeys"]): {
                type  = "SSHFP"
                name  = join(".", [key, var.name])
                value = null
                data  = {
                    algorithm   = local.SSHFP_SPEC["ssh-${alg}"]
                    type        = 2 # SHA256
                    fingerprint = data.external.key2fp[key].result["ssh-${alg}"]
                }
            }
        ]
    ]),
    flatten([
        for key, values in var.public_instances: [
            for alg in keys(values["hostkeys"]): {
                type  = "SSHFP"
                name  = var.name
                value = null
                data  = {
                    algorithm   = local.SSHFP_SPEC["ssh-${alg}"]
                    type        = 2 # SHA256
                    fingerprint = data.external.key2fp[key].result["ssh-${alg}"]
                }
            }
        ]
        if contains(values["tags"], var.domain_tag)
    ]),
    )
}

output "records" {
    value = local.records
}
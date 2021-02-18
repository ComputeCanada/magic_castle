variable "name" {
}

variable "login_ips" {
  type = list(string)
}

variable "rsa_public_key" {
}

data "external" "key2fp" {
  program = ["python", "${path.module}/key2fp.py"]
  query = {
    ssh_key = var.rsa_public_key
  }
}

locals {
    name_A = [
        for ip in var.login_ips : {
            type  = "A"
            name  = var.name
            value = ip
            data  = null
        }
    ]
    login_A = [
        for index in range(length(var.login_ips)) : {
            type  = "A"
            name  = join(".", [format("login%d", index + 1), var.name])
            value = var.login_ips[index]
            data  = null
        }
    ]
    jupyter_A = [
        for ip in var.login_ips : {
            type  = "A"
            name  = join(".", ["jupyter", var.name])
            value = ip
            data  = null
        }
    ]
    ipa_A = [
        for ip in var.login_ips : {
            type  = "A"
            name  = join(".", ["ipa", var.name])
            value = ip
            data  = null
        }
    ]
    dtn_A = [
        for ip in var.login_ips : {
            type  = "A"
            name  = join(".", ["dtn", var.name])
            value = ip
            data  = null
        }
    ]
    mokey_A = [
        for ip in var.login_ips : {
            type  = "A"
            name  = join(".", ["mokey", var.name])
            value = ip
            data  = null
        }
    ]
    name_SSHFP = [
        {
            type  = "SSHFP"
            name  = var.name
            value = null
            data  = {
                algorithm   = data.external.key2fp.result["algorithm"]
                type        = 2
                fingerprint = data.external.key2fp.result["sha256"]
            }
        }
    ]
    login_SSHFP = [
        for index in range(length(var.login_ips)) : {
            type  = "SSHFP"
            name  = join(".", [format("login%d", index + 1), var.name])
            value = null
            data  = {
                algorithm   = data.external.key2fp.result["algorithm"]
                type        = 2
                fingerprint = data.external.key2fp.result["sha256"]
            }
        }
    ]
}

output "records" {
    value = concat(
        local.name_A,
        local.login_A,
        local.jupyter_A,
        local.ipa_A,
        local.dtn_A,
        local.mokey_A,
        local.name_SSHFP,
        local.login_SSHFP
    )
}
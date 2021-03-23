module "record_generator" {
  source         = "../record_generator"
  name           = lower(var.name)
  public_instances = var.public_instances
  domain_tag       = var.domain_tag
  vhost_tag        = var.vhost_tag
}

resource "local_file" "dns_record" {
    content     = <<EOT
; Import this file in ${var.domain} DNS zone
%{ for record in module.record_generator.records ~}
${record.name}.${var.domain}.   1   IN  ${record.type}  %{ if record.value != null }${record.value}%{ else }${record.data["algorithm"]} ${record.data["type"]}  ${record.data["fingerprint"]}%{ endif }
%{ endfor ~}
EOT
    filename = "${var.name}.${var.domain}.txt"
    file_permission = "0600"
}

output "hostnames" {
  value = distinct(compact([for record in module.record_generator.records : join(".", [record.name, var.domain]) if record.type == "A" ]))
}
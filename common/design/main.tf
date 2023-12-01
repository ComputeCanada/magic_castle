data "http" "agent_ip" {
  url = "http://ipv4.icanhazip.com"
}

locals {
  domain_name = "${lower(var.cluster_name)}.${lower(var.domain)}"

  instances = merge(
    flatten([
      for prefix, attrs in var.instances : [
        for i in range(lookup(attrs, "count", 1)) : {
          (format("%s%d", prefix, i + 1)) = merge(
            { for attr, value in attrs : attr => value if attr != "count" },
            { prefix = prefix }
          )
        }
      ]
    ])...
  )

  instances_to_build = {
    for key, values in local.instances: key => values
    if ! contains(values.tags, "pool") || contains(var.pool, key)
  }

  instance_per_volume = merge([
    for ki, vi in var.volumes : {
      for kj, vj in vi :
      "${ki}-${kj}" => merge({
        instances = [for x, values in local.instances_to_build : x if contains(values.tags, ki)]
      }, vj)
    }
  ]...)

  volumes = merge([
    for key, values in local.instance_per_volume : {
      for instance in values["instances"] :
      "${instance}-${key}" => merge(
        { for key, value in values : key => value if key != "instances" },
      { instance = instance })
    }
  ]...)

  volume_per_instance = transpose({ for key, value in local.instance_per_volume : key => value["instances"] })

  # We look for a firewall rule that allow SSH connection from the Terraform agent's ip
  # and we memorize the corresponding tag so we can determine which instances can be used as a
  # first hop when transferring files or executing remote commands with Terraform.
  # There are room for improvements, but we don't expect users to be very creative with
  # firewall rules, so we are keeping the algorithm simple for now. One aspect
  #  that could be improved:
  # 1. We don't validate if the tag is actually present in any instance, we simply take the
  # first value, so if there are more than one firewall rules that matches the criteria
  # but only one that is actually active, we might select the wrong tag. It would be better
  # to keep all firewall tags that match the criteria, then identify the intersection with
  # instance tags and select any tag that matches.
  agent_ip = chomp(data.http.agent_ip.response_body)
  bastion_tag = try(
    element([
        for rule, values in var.firewall_rules:
        values.tag
        if values.ethertype == "IPv4" &&
        22 <= values.from_port && values.to_port <= 22 &&
        alltrue([
          for i, v in split(".", local.agent_ip):
            tonumber(split(".", cidrhost(values.cidr, 0))[i]) <= tonumber(v) &&
            tonumber(v) <= tonumber(split(".", cidrhost(values.cidr, -1))[i])
        ])
      ],
    0),
  "")
}

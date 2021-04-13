locals {
  domain_name = "${lower(var.cluster_name)}.${lower(var.domain)}"
  
  instances = merge(
    flatten([
      for hostname, attrs in var.instances : [
        for i in range(lookup(attrs, "count", 1)) : {
          (format("%s%d", hostname, i + 1)) = { for attr, value in attrs : attr => value if attr != "count" }
        }
      ]
    ])...
  )

  host2prefix = merge(
    flatten([
      for hostname, attrs in var.instances : [
        for i in range(lookup(attrs, "count", 1)) : {
          (format("%s%d", hostname, i + 1)) = hostname
        }
      ]
    ])...
  )

  instance_per_volume = merge([
    for ki, vi in var.volumes : {
      for kj, vj in vi :
      "${ki}-${kj}" => merge({
        instances = [for x, values in local.instances : x if contains(values.tags, ki)]
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
  
  all_tags = toset(flatten([for key, values in local.instances : values["tags"]]))
}

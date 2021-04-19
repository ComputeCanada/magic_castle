# Magic Castle Migration Guide

## Magic Castle 10.x to 11.x

Here are some helpful tips for migrating from using Magic Castle 10.x to 11.x.

Note that live clusters cannot be simply migrated from 10 to 11. This guide is
only meant to help you migrating existing Terraform code, not cloud resources.

### main.tf: `instances`

The first major change is the structure for the `instances` variable.
In MC 10, the instances were defined like this:
```hcl
instances = {
    mgmt  = { type = "p4-6gb", count = 1 }
    login = { type = "p2-3gb", count = 1 }
    node  = [
        { type = "p2-3gb", count = 1 }
        { type = "g1-10gb-60", count = 1, prefix = "gpu" }
    ]
}
```

In MC 11, the same architecture is defined like this:
```hcl
instances = {
    mgmt     = { type = "p4-6gb", tags = ["puppet", "mgmt", "nfs"] }
    login    = { type = "p2-3gb", tags = ["login", "public", "proxy"] }
    node     = { type = "p2-3gb", tags = ["node"], count = 1 }
    gpu-node = { type = "g1-8gb-c4-22gb", tags = ["node"], count = 1 }
}
```

List of changes:
1. Each instance' purpose in the cluster is now defined by a list
of tags instead of using its hostname. The role of each tag is
documented [here](README.md). The hostname of the instances is
therefore no longer limited to `mgmt`, `login` or `node`.
2. To define heterogenous compute nodes, `prefix` is no longer used.
Instead, a new entry with a distinct hostname prefix is defined.
3. The count parameter is now optional and has a default value of 1.
Instance hostnames still include the index number, even when count
is not defined.

Note that it is possible to move the tags, and create more instances with
these tags. For example, to move the Puppet main server on an instance
separate of `mgmt1`, one could do:
```hcl
instances = {
    puppet   = { type = "p4-6gb", tags = ["puppet"]}
    mgmt     = { type = "p4-6gb", tags = ["mgmt", "nfs"] }
    login    = { type = "p2-3gb", tags = ["login", "public", "proxy"] }
    node     = { type = "p2-3gb", tags = ["node"], count = 1 }
}
```

### main.tf: `storage` -> `volumes`

The second major change is `storage` has been replaced by the `volumes`.
In MC 10, it was possible to define only three volumes attached to `mgmt1`
with the following code:
```hcl
storage = {
    type         = "nfs"
    home_size    = 100
    project_size = 100
    scratch_size = 100
}
```

In MC 11, the same volumes attached to `mgmt1` are defined like this
```hcl
volumes = {
    nfs = {
        home    = { size = 100 }
        project = { size = 100 }
        scratch = { size = 100, type = "volumes-ssd" }
    }
}
```

List of changes:
1. `type` is removed. Instead, a set of volumes gets to share the same
arbitrary tag, in the case above `nfs`.
2. For each instance with a tag matching of the volume tag, Magic Castle
will create the set of matching volume and attach them to the instance.
3. It is now possible to define the volume type. If left unspecified,
the cloud provider default for volume type is used.
4. Removing an instance will delete the corresponding volumes. It is no
longer possible to maintain the `home`, `project` and `scratch` volumes
while setting the `mgmt` count at 0.

### main.tf: Other changes

- `root_disk_size` variable has been removed. You can define the root
disk size of each instance type independtly by defining `disk_size`
in the instance attributes' map.
- Azure `managed_disk_type` has been removed. The disk type can be
defined for instances using the `disk_type` attribute in the instance
attributes' map and the disk type for attached volume can be defined
with `type` in the volumes map. This attribute works for every cloud
provider, not only Azure.

### Puppet: `terraform_data.yaml` format

Instead of fetching a template of a YAML file, Magic Castle now writes
a its own YAML file that is than integrated in the Puppet data hierarchy.

In MC 10, `terraform_data.yaml` looked like this when populated on `mgmt1`
```yaml
---
profile::base::sudoer_username: "centos"

profile::consul::acl_api_token: "123-abc-def-456"

profile::freeipa::base::admin_passwd: "aaaaBBBBcccDDee"
profile::freeipa::base::domain_name: "phoenix.calculquebec.cloud"
profile::freeipa::mokey::passwd: "aaaaBBBBcccDDee"

profile::accounts::guests::passwd: "sneaky.sensitive.girafe"
profile::accounts::guests::nb_accounts: 10

profile::slurm::base::cluster_name: "phoenix"
profile::slurm::base::munge_key: "aaaBbbCc1231aF"
profile::slurm::accounting::password: "aaaaBBBBcccDDee"

profile::freeipa::client::server_ip: "10.0.0.0.2"
profile::consul::client::server_ip: "10.0.0.2"
profile::nfs::client::server_ip: "10.0.0.2"

profile::nfs::server::home_devices: "/dev/disk/by-id/virtio-*"
profile::nfs::server::project_devices: "/dev/disk/by-id/virtio-*"
profile::nfs::server::scratch_devices: "/dev/disk/by-id/virtio-*"

profile::reverse_proxy::domain_name: "phoenix.calculquebec.cloud"
```

In MC 11, the `terraform_data.yaml` matching the preceding `instances` and `volumes`
configuration could look like this:
```yaml
terraform:
  instances:
    mgmt1:
      local_ip: "10.0.0.1"
      public_ip: ""
      tags: ["puppet", "nfs", "mgmt"]
      hostkeys:
        rsa: "ssh-rsa ..."
    login1:
      local_ip: "10.0.0.2"
      public_ip: "132.219.29.10"
      tags: ["login", "public", "proxy"]
      hostkeys:
        rsa: "ssh-rsa ..."
    node1:
      local_ip: "10.0.0.3"
      public_ip: ""
      tags: ["node"]
      hostkeys:
        rsa: "ssh-rsa ..."
    gpu-node1:
      local_ip: "10.0.0.4"
      public_ip: ""
      tags: ["node"]
      hostkeys:
        rsa: "ssh-rsa ..."
  volumes:
    nfs:
      home:
        - "/dev/disk/by-id/virtio-*"
      project:
        - "/dev/disk/by-id/virtio-*"
      scratch:
        - "/dev/disk/by-id/virtio-*"
  tag_ip:
    mgmt:
      - 10.0.0.1
    nfs:
      - 10.0.0.1
    puppet:
      - 10.0.0.1
    login:
      - 10.0.0.2
    node:
      - 10.0.0.3
    gpu-node:
      - 10.0.0.4
  data:
    cluster_name: "phoenix"
    consul_token: "123-abc-def-456"
    domain_name: "phoenix.calculquebec.cloud"
    freeipa_passwd: "aaaaBBBBcccDDee"
    guest_passwd: "sneaky.sensitive.girafe"
    munge_key: "aaaBbbCc1231aF"
    nb_users: 10
    sudoer_username: "centos"
```

The values from `terraform_data.yaml` are input in Puppet classes hieradata
using aliases in `common.yaml`. For example, to number of guest accounts
that corresponds to `profile::accounts::guests::nb_accounts` is set to
the `nb_users` value like this in `common.yaml`:
```yaml
profile::accounts::guests::nb_accounts: "%{alias('terraform.data.nb_users')}"
```

**Important note**: Because `terraform_data.yaml` now includes information about the
resources, it will be overwritten every time something is modified in `main.tf`. It
is therefore no longer recommended to edit it manually. All changes to this file
should be perform by Terraform. The [documentation](README.md) has been
updated accordingly.
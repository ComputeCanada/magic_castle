## Magic Castle Terraform Structure

Figure 1 (below) illustrates how Magic Castle is structured to provide a unified interface between multiple
cloud providers. Each blue block is a file or a module, while white blocks are variables or resources.
Arrows indicate variables or resources that contribute to the definition of the linked variables or
resources. The figure can be read as a flow-chart from top to bottom. Some resources and variables have been left out of the chart to avoid cluttering it further.

![Magic Castle Terraform Structure](https://docs.google.com/drawings/d/e/2PACX-1vSL84MSd1rz5hgjLMfWBBKwp6-jNTEJovNUOXtTwDovpvmyFG7qo12HD32a3fhaKl8hpjcIfM5fZ8II/pub?w=1864&h=1972)
*Figure 1. Magic Castle Terraform Project Structure*

1. `main.tf`: User provides the instances and volumes structure they wants as _map_s.
    ```hcl
    instances = {
      mgmt  = { type = "p4-7.5gb", tags = ["puppet", "mgmt", "nfs"] }
      login = { type = "p2-3.75gb", tags = ["login", "public", "proxy"] }
      node  = { type = "p2-3.75gb", tags = ["node"], count = 2 }
    }

    volumes = {
      nfs = {
        home     = { size = 100 }
        project  = { size = 500 }
        scratch  = { size = 500 }
      }
    }
    ```
2. `common/design`: 
    1. the `instances` map is expanded to form a new map where each entry represents a single host.
        ```hcl
        instances = {
          mgmt1 = {
            type = "p2-3.75gb"
            tags = ["puppet", "mgmt", "nfs"]
          }
          login1 = {
            type = "p2-3.75gb"
            tags = ["login", "public", "proxy"]
          }
          node1 = {
            type = "p2-3.75gb"
            tags = ["node"]
          }
          node2 = {
            type = "p2-3.75gb"
            tags = ["node"]
          }
        }
        ```
    2. the `volumes` map is expanded to form a new map where each entry represent a single volume
        ```hcl
        volumes = {
          mgmt1-nfs-home    = { size = 100 }
          mgmt1-nfs-project = { size = 100 }
          mgmt1-nfs-scratch = { size = 500 }
        }
        ```

3. `network.tf`: the `instances` map from `common/design` is used to generate a network interface (nic)
for each host, and a public ip address for each host with the `public` tag. The local
ip address retrieved from the nic of the instance tagged `puppet` is outputted as `puppetserver_ip`.
    ```hcl
    resource "provider_network_interface" "nic" {
      for_each = module.design.instances
      ...
    }
    ```

4. `common/instance_config`: for each host in `instances`, a [cloud-init]() yaml config that includes
`puppetserver_ip` is generated. These configs are outputted to a `user_data` map where the keys are
the hostnames.
    ```hcl
    user_data = {
      for key, values in var.instances :
        key => templatefile("${path.module}/puppet.yaml", { ... })
    }
    ```

5. `infrastructure.tf`: for each host in `instances`, an instance resource as defined by the selected
cloud provider is generated. Each instance is initially configured by its `user_data` cloud-init
yaml config.
    ```hcl
    resource "provider_instance" "instances" {
      for_each  = module.design.instance
      user_data = module.instance_config.user_data[each.key]
      ...
    }
    ```

6. `infrastructure.tf`: for each volume in `volumes`, a block device as defined by the selected
cloud provider is generated and attached it to its matching instance using an `attachment` resource.
    ```hcl
    resource "provider_volume" "volumes" {
      for_each = module.design.volumes
      size     = each.value.size
      ...
    }
    resource "provider_attachment" "attachments" {
      for_each    = module.design.volumes
      instance_id = provider_instance.instances[each.value.instance].id
      volume_id   = provider_volume.volumes[each.key].id
      ...
    }
    ```

7. `infrastructure.tf`: the created instances' information are consolidated in a map
output as `all_instances`.
    ```hcl
    all_instances = {
      mgmt1 = {
        public_ip = ""
        local_ip  = "10.0.0.1"
        id        = "abc1213-123-1231"
        hostkey   = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAB"
        tags      = ["mgmt", "puppet", "nfs"]
      }
      ...
    }
    ```
6. `common/cluster_config`: the information from created instances is consolidated in `all_instances`
and written in a [yaml file](../common/cluster_config/terraform_data.yaml) that is uploaded on
the Puppet server as part of the hieradata.
    ```hcl
    resource "null_resource" "deploy_hieradata" {
      ...
      provisioner "file" {
        content     = local.hieradata
        destination = "terraform_data.yaml"
      }
      ...
    }
    ```

7. `outputs.tf`: the information of all instances that have a public address are output as a
map named `public_instances`.

## Resource per provider

In the previous section, we have used generic resource name when writing HCL code that
defines these resources. The following table indicate what resource is used for each
provider based on its role in the cluster.

| Resource    | [AWS](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | [Azure](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs) | [Google Cloud Platform](https://registry.terraform.io/providers/hashicorp/google/latest/docs) | [OpenStack](https://registry.terraform.io/providers/terraform-provider-openstack/openstack/latest/docs/) | OVH                                |
| ----------- | :-------------------- | :------------------------------------------- | :---------------------------- | ---------------------------------- | :--------------------------------- |
| network     | [aws_vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | [azurerm_virtual_network](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) | [google_compute_network](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_network) | prebuilt | openstack_networking_network_v2 |
| subnet      | [aws_subnet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | [azurerm_subnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | [google_compute_subnetwork](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_subnetwork) | prebuilt | openstack_networking_subnet_v2 |
| router      | [aws_route](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | not used | [google_compute_router](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router) | built-in | not used |
| nat         | [aws_internet_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) | not used | [google_compute_router_nat](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router_nat) | built-in | not used |
| firewall    | [aws_security_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | [azurerm_network_security_group](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group) | [google_compute_firewall](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | [openstack_compute_secgroup_v2](https://registry.terraform.io/providers/terraform-provider-openstack/openstack/latest/docs/resources/compute_secgroup_v2) | openstack_compute_secgroup_v2 |
| nic         | [aws_network_interface](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_interface) | [azurerm_network_interface](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface) | [google_compute_address](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_address) | [openstack_networking_port_v2](https://registry.terraform.io/providers/terraform-provider-openstack/openstack/latest/docs/resources/networking_port_v2) | openstack_networking_port_v2       |
| public ip   | [aws_eip](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | [azurerm_public_ip](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) | [google_compute_address](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_address) | [openstack_networking_floatingip_v2](https://registry.terraform.io/providers/terraform-provider-openstack/openstack/latest/docs/resources/networking_floatingip_v2) | openstack_networking_network_v2    |
| instance    | [aws_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | [azurerm_linux_virtual_machine](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_virtual_machine) | [google_compute_instance](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance) | [openstack_compute_instance_v2](https://registry.terraform.io/providers/terraform-provider-openstack/openstack/latest/docs/resources/compute_instance_v2) | openstack_compute_instance_v2 |
| volume      | [aws_ebs_volume](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ebs_volume) | [azurerm_managed_disk](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/managed_disk) | [google_compute_disk](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_disk) | [openstack_blockstorage_volume_v3](https://registry.terraform.io/providers/terraform-provider-openstack/openstack/latest/docs/resources/blockstorage_volume_v3)   | openstack_blockstorage_volume_v3   |
| attachment  | [aws_volume_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/volume_attachment) | [azurerm_virtual_machine_data_disk_attachment](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_data_disk_attachment) | [google_compute_attached_disk](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_attached_disk)  | [openstack_compute_volume_attach_v2](https://registry.terraform.io/providers/terraform-provider-openstack/openstack/latest/docs/resources/compute_volume_attach_v2) | openstack_compute_volume_attach_v2 |

## Using reference design to extend for a new cloud provider

Magic Castle currently supports five cloud providers, but its design makes it easy to add
new providers. This section presents a step-by-step guide to add a new cloud provider
support to Magic Castle.

1. **Identify the resources**. Using the _Resource per provider_ table, read the cloud provider
Terraform documentation, and identify the name for each resource in the table.

2. **Check minimum requirements**. Once all resources have been identified, you should be able to
determine if the cloud provider can be used to deploy Magic Castle. If you found a name for each
resource listed in table, the cloud provider can be supported. If some resources are missing, you
will need to do read the provider's documentation to determine if the absence of the resource can
be compensated for somehow.

3. **Initialize the provider folder**. Create a folder named after the provider. In this folder, create
two symlinks, one pointing to `common/variables.tf` and the other to `common/outputs.tf`. These
files define the interface common to all providers supported by Magic Castle.

4. **Define cloud provider specifics variables**. Create a file named after your provider
`provider_name.tf` and define variables that are required by the provider but not common to all
providers, for example the availability zone or the region.

5. **Initialize the infrastructure**. Create a file named  `infrastructure.tf`. In this file,
define the provider if it requires input parameters (for example the region)
and include the `common/design` module.
    ```hcl
    provider "provider_name" {
      region = var.region
    }

    module "design" {
      source       = "../common/design"
      cluster_name = var.cluster_name
      domain       = var.domain
      instances    = var.instances
      volumes      = var.volumes
    }
    ```

6. **Create the networking infrastructure**. Create a file named `network.tf`
and define the network, subnet, router, nat, firewall, nic and public ip resources using
the `module.design.instances` map.

7. **Create the instance configurations**. In `infrastructure.tf`, include the
`common/instance_config` module and provide the required input parameters.
  ```hcl
  module "instance_config" {
    source = "../common/instance_config"
    ...
  }
  ```
8. **Create the instances**. In `infrastructure.tf`, define the `instances` resource using
`module.design.instances` for the instance attributes and `module.instance_config.user_data`
for the initial configuration.

9. **Create the volumes**. In `infrastructure.tf`, define the `volumes` resource using
`module.design.volumes`.

10. **Attach the volumes**. In `infrastructure.tf`, define the `attachments` resource using
`module.design.volumes` and refer to the attribute `each.value.instance` to retrieve the
instance's id to which the volume needs to be attached.

11. **Consolidate the instances' information**.  In `infrastructure.tf`, define a local
variable named `all_instances` that will be a map containing the following keys
(for each created instance): `id`, `public_ip`, `local_ip`, `tags`, `hostkeys`, where `hostkeys`
is also a map with a key named `rsa` that correspond to the instance hostkey.

12. **Consolidate the volume device information**. In `infrastructure.tf`, define a local
variable named `volume_devices` implementing the following logic in HCL. Replace
the line starting by `/dev/disk/by-id` with the proper logic that would match the volume
resource to its device path from within the instance to which it is attached.
  ```hcl
  volume_devices = {
    for ki, vi in var.volumes :
    ki => {
      for kj, vj in vi :
      kj => [for key, volume in module.design.volumes :
        "/dev/disk/by-id/*${substr(provider_volume.volumes["${volume["instance"]}-${ki}-${kj}"].id, 0, 20)}"
        if key == "${volume["instance"]}-${ki}-${kj}"
      ]
    }
  }
  ```

13. **Create the cluster configuration and upload**. In `infrastructure.tf`, include the
`common/cluster_config` module and provide the required input parameters.

### An example

1. **Identify the resources**. For Digital Ocean, Oracle Cloud and Alibaba Cloud, we get the following resource mapping:
    | Resource    | [Digital Ocean](https://registry.terraform.io/providers/digitalocean/digitalocean/latest/docs) | [Oracle Cloud](https://registry.terraform.io/providers/hashicorp/oci/latest/docs) | [Alibaba Cloud](https://registry.terraform.io/providers/aliyun/alicloud/latest/docs) |
    | ----------- | :-------------------- |  :-------------------- |  :-------------------- |
    | network     | [digitalocean_vpc](https://registry.terraform.io/providers/digitalocean/digitalocean/latest/docs/resources/vpc) | [oci_core_vcn](https://registry.terraform.io/providers/hashicorp/oci/latest/docs/resources/core_vcn) | [alicloud_vpc](https://registry.terraform.io/providers/aliyun/alicloud/latest/docs/resources/vpc) |
    | subnet      | built in vpc | [oci_subnet](https://registry.terraform.io/providers/hashicorp/oci/latest/docs/resources/core_subnet) | [alicloud_vswitch](https://registry.terraform.io/providers/aliyun/alicloud/latest/docs/resources/vswitch) |
    | router      | n/a          | [oci_core_route_table](https://registry.terraform.io/providers/hashicorp/oci/latest/docs/resources/core_route_table) | built in vpc |
    | nat         | n/a          | [oci_core_internet_gateway](https://registry.terraform.io/providers/hashicorp/oci/latest/docs/resources/core_internet_gateway) | [alicloud_nat_gateway](https://registry.terraform.io/providers/aliyun/alicloud/latest/docs/resources/nat_gateway) |
    | firewall    | [digitalocean_firewall](https://registry.terraform.io/providers/digitalocean/digitalocean/latest/docs/resources/firewall) | [oci_core_security_list](https://registry.terraform.io/providers/hashicorp/oci/latest/docs/resources/core_security_list) | [alicloud_security_group](https://registry.terraform.io/providers/aliyun/alicloud/latest/docs/resources/security_group) |
    | nic         | n/a | built in instance | [alicloud_network_interface](https://registry.terraform.io/providers/aliyun/alicloud/latest/docs/resources/network_interface) |
    | public ip   | [digitalocean_floating_ip](https://registry.terraform.io/providers/digitalocean/digitalocean/latest/docs/resources/floating_ip) | built in instance | [alicloud_eip](https://registry.terraform.io/providers/aliyun/alicloud/latest/docs/resources/eip) |
    | instance    | [digitalocean_droplet](https://registry.terraform.io/providers/digitalocean/digitalocean/latest/docs/resources/droplet) | [oci_core_instance](https://registry.terraform.io/providers/hashicorp/oci/latest/docs/resources/core_instance) | [alicloud_instance](https://registry.terraform.io/providers/aliyun/alicloud/latest/docs/resources/instance) |
    | volume      | [digitalocean_volume](https://registry.terraform.io/providers/digitalocean/digitalocean/latest/docs/resources/volume) | [oci_core_volume](https://registry.terraform.io/providers/hashicorp/oci/latest/docs/resources/core_volume) | [alicloud_disk](https://registry.terraform.io/providers/aliyun/alicloud/latest/docs/resources/disk) |
    | attachment  | [digitalocean_volume_attachment](https://registry.terraform.io/providers/digitalocean/digitalocean/latest/docs/resources/volume_attachment) | [oci_core_volume_attachment](https://registry.terraform.io/providers/hashicorp/oci/latest/docs/resources/core_volume_attachment) | [alicloud_disk_attachment](https://registry.terraform.io/providers/aliyun/alicloud/latest/docs/resources/disk_attachment) |

2. **Check minimum requirements**. In the preceding table, we can see Digital Ocean does not have the ability
to define a network interface. The documentation also leads us to conclude that it is not possible
to define the private ip address of the instances before creating them. Because the Puppet server
ip address is required before generating the cloud-init YAML config for all instances, including the Puppet
server itself, this means it impossible to use Digital Ocean to spawn a Magic Castle cluster.
<br><br>
Oracle Cloud presents the same issue, however, after reading the instance documentation, we find that
it is possible to define a static ip address as a string in the instance attribute. It would therefore
be possible to create a datastructure in Terraform that would associate each instance hostname with
an ip address in the subnet CIDR.
<br><br>
Alibaba cloud has an answer for each resource, so we will use this provider in the following steps.

3. **Initialize the provider folder**. In a terminal:
  ```bash
  git clone https://github.com/ComputeCanada/magic_castle.git
  cd magic_castle
  mkdir alicloud
  cd aliclcoud
  ln -s ../common/{variables,outputs}.tf .
  ```

4. **Define cloud provider specifics variables**. Add the following to a new file `alicloud.tf`:
  ```hcl
  variable "region" { }
  locals {
    cloud_provider  = "alicloud"
    cloud_region    = var.region
  }
  ```

5. **Initialize the infrastructure**. Add the following to a new file `infrastructure.tf`:
  ```hcl
  provider "alicloud" {
    region = var.region
  }

  module "design" {
    source       = "../common/design"
    cluster_name = var.cluster_name
    domain       = var.domain
    instances    = var.instances
    volumes      = var.volumes
  }
  ```

6. **Create the networking infrastructure**. `network.tf` base template:
  ```hcl
  resource "alicloud_vpc" "network" { }
  resource "alicloud_vswitch" "subnet" { }
  resource "alicloud_nat_gateway" "nat" { }
  resource "alicloud_security_group" "firewall" { }
  resource "alicloud_security_group_rule" "allow_in_services" { }
  resource "alicloud_security_group" "allow_any_inside_vpc" { }
  resource "alicloud_security_group_rule" "allow_ingress_inside_vpc" { }
  resource "alicloud_security_group_rule" "allow_egress_inside_vpc" { }
  resource "alicloud_network_interface" "nic" { }
  resource "alicloud_eip" "public_ip" { }
  resource "alicloud_eip_association" "eip_asso" { }

  locals {
    puppetserver_ip = [
        for x, values in module.design.instances : alicloud_network_interface.nic[x].private_ip
        if contains(values.tags, "puppet")
    ]
  }
  ```

7. **Create the instance configuration**. Add the following to `infrastructure.tf`:
  ```hcl
  module "instance_config" {
    source           = "../common/instance_config"
    instances        = module.design.instances
    config_git_url   = var.config_git_url
    config_version   = var.config_version
    puppetserver_ip  = local.puppetserver_ip
    sudoer_username  = var.sudoer_username
    public_keys      = var.public_keys
    generate_ssh_key = var.generate_ssh_key
  }
  ```

8. **Create the instances**. Add and complete the following snippet to `infrastructure.tf`:
  ```hcl
  resource "alicloud_instance" "instances" {
    for_each = module.design.instances
  }
  ```

9. **Create the volumes**. Add and complete the following snippet to `infrastructure.tf`:
  ```hcl
  resource "alicloud_disk" "volumes" {
    for_each = module.design.volumes
  }
  ```

10. **Attach the volumes**. Add and complete the following snippet to `infrastructure.tf`:
  ```hcl
  resource "alicloud_disk_attachment" "attachments" {
    for_each = module.design.volumes
  }
  ```

11. **Consolidate the instances' information**. Add the following snippet to `infrastructure.tf`:
  ```hcl
  locals {
    all_instances = { for x, values in module.design.instances :
      x => {
        public_ip   = contains(values["tags"], "public") ? alicloud_eip.public_ip[x].public_ip : ""
        local_ip    = alicloud_network_interface.nic[x].private_ip
        tags        = values["tags"]
        id          = alicloud_instance.instances[x].id
        hostkeys    = {
          rsa = module.instance_config.rsa_hostkeys[x]
        }
      }
    }
  }
  ```
12. **Consolidate the volume devices' information**. Add the following snippet to `infrastructure.tf`:
  ```hcl
  volume_devices = {
    for ki, vi in var.volumes :
    ki => {
      for kj, vj in vi :
      kj => [for key, volume in module.design.volumes :
        "/dev/disk/by-id/virtio-${replace(alicloud_disk.volumes["${volume["instance"]}-${ki}-${kj}"].id, "d-", "")}"
        if key == "${volume["instance"]}-${ki}-${kj}"
      ]
    }
  }
  ```

13.  **Create the cluster configuration and upload**. Add the following snippet to `infrastructure.tf`.
  ```hcl
  module "cluster_config" {
    source          = "../common/cluster_config"
    instances       = local.all_instances
    nb_users        = var.nb_users
    hieradata       = var.hieradata
    software_stack  = var.software_stack
    cloud_provider  = local.cloud_provider
    cloud_region    = local.cloud_region
    sudoer_username = var.sudoer_username
    guest_passwd    = var.guest_passwd
    domain_name     = module.design.domain_name
    cluster_name    = var.cluster_name
    volume_devices  = local.volume_devices
    private_ssh_key = module.instance_config.private_key
  }
  ```

Once your new provider is written, you can write an example that will use the module
to spawn a Magic Castle cluster with that provider.
  ```hcl
  module "alicloud" {
    source         = "./alicloud"
    config_git_url = "https://github.com/ComputeCanada/puppet-magic_castle.git"
    config_version = "main"

    cluster_name = "new"
    domain       = "my.cloud"
    image        = "centos_7_9_x64_20G_alibase_20210318.vhd"
    nb_users     = 10

    instances = {
      mgmt   = { type = "ecs.g6.large", tags = ["puppet", "mgmt", "nfs"] }
      login  = { type = "ecs.g6.large", tags = ["login", "public", "proxy"] }
      node   = { type = "ecs.g6.large", tags = ["node"], count = 1 }
    }

    volumes = {
      nfs = {
        home     = { size = 10 }
        project  = { size = 50 }
        scratch  = { size = 50 }
      }
    }

    public_keys = [file("~/.ssh/id_rsa.pub")]

    # Alicloud specifics
    region  = "us-west-1"
  }
  ```

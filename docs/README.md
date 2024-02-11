# Magic Castle Documentation

<p><img src="img/logo.png" width="50%"/></p>

## Table of Content

1. [Setup](#1-setup)
2. [Cloud Cluster Architecture Overview](#2-cloud-cluster-architecture-overview)
3. [Initialization](#3-initialization)
4. [Configuration](#4-configuration)
5. [Cloud Specific Configuration](#5-cloud-specific-configuration)
6. [DNS Configuration and SSL Certificates](#6-dns-configuration-and-wildcard-ssl-certificate)
7. [Planning](#7-planning)
8. [Deployment](#8-deployment)
9. [Destruction](#9-destruction)
10. [Customize Cluster Software Configuration](#10-customize-cluster-software-configuration)
11. [Customize Magic Castle Terraform Files](#11-customize-magic-castle-terraform-files)

## 1. Setup

To use Magic Castle you will need:
1. Terraform (>= 1.4.0)
2. Authenticated access to a cloud
3. Ability to communicate with the cloud provider API from your computer
4. A project with operational limits meeting the requirements described in _Quotas_ subsection.
5. ssh-agent running and tracking your SSH key

### 1.1 Terraform

To install Terraform, follow the
[tutorial](https://learn.hashicorp.com/tutorials/terraform/install-cli)
or go directly on [Terraform download page](https://www.terraform.io/downloads).

You can verify Terraform was properly installed by looking at the version in a terminal:
```
terraform version
```

### 1.2 Authentication

#### 1.2.1 Amazon Web Services (AWS)
<!-- markdown-link-check-disable -->
1. Go to [AWS - My Security Credentials](https://console.aws.amazon.com/iam/home?#/security_credentials)
2. Create a new access key.
3. In a terminal, export `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`, environment variables, representing your AWS Access Key and AWS Secret Key:
    ```shell
    export AWS_ACCESS_KEY_ID="an-access-key"
    export AWS_SECRET_ACCESS_KEY="a-secret-key"
    ```
<!-- markdown-link-check-enable -->

Reference: [AWS Provider - Environment Variables](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#environment-variables)

#### 1.2.2 Google Cloud

1. Install the [Google Cloud SDK](https://cloud.google.com/sdk/docs/downloads-interactive)
2. In a terminal, enter : `gcloud auth application-default login`

#### 1.2.3 Microsoft Azure

1. Install [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
2. In a terminal, enter : `az login`

Reference : [Azure Provider: Authenticating using the Azure CLI](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/azure_cli)

#### 1.2.4 OpenStack / OVH

1. Download your OpenStack Open RC file.
It is project-specific and contains the credentials used
by Terraform to communicate with OpenStack API.
To download, using OpenStack web page go to:
**Project** → **API Access**, then click on **Download OpenStack RC File**
then right-click on **OpenStack RC File (Identity API v3)**, **Save Link as...**,
and save the file.

2. In a terminal located in the same folder as your OpenStack RC file,
source the OpenStack RC file:
    ```
    source *-openrc.sh
    ```
This command will ask for a password, enter your OpenStack password.

### 1.3 Cloud API

Once you are authenticated with your cloud provider, you should be able to
communicate with its API. This section lists for each provider some
instructions to test this.

#### 1.3.1 AWS

1. In a dedicated temporary folder, create a file named `test_aws.tf`
with the following content:
    ```hcl
    provider "aws" {
      region = "us-east-1"
    }

    data "aws_ec2_instance_type" "example" {
      instance_type = "t2.micro"
    }
    ```
2. In a terminal, move to where the file is located, then:
    ```shell
    terraform init
    ```
3. Finally, test terraform communication with AWS:
    ```
    terraform plan
    ```
    If everything is configured properly, terraform will output:
    ``` 
    No changes. Your infrastructure matches the configuration.
    ```
    Otherwise, it will output:
    ```
    Error: error configuring Terraform AWS Provider: no valid credential sources for Terraform AWS Provider found.
    ```
4. You can delete the temporary folder and its content.

#### 1.3.2 Google Cloud

In a terminal, enter:
```
gcloud projects list
```
It should output a table with 3 columns
```
PROJECT_ID NAME PROJECT_NUMBER
```

Take note of the `project_id` of the Google Cloud project you want to use,
you will need it later.

#### 1.3.3 Microsoft Azure

In a terminal, enter:
```
az account show
```
It should output a JSON dictionary similar to this:
```json
{
  "environmentName": "AzureCloud",
  "homeTenantId": "98467e3b-33c2-4a34-928b-ed254db26890",
  "id": "4dda857e-1d61-457f-b0f0-e8c784d1fb20",
  "isDefault": true,
  "managedByTenants": [],
  "name": "Pay-As-You-Go",
  "state": "Enabled",
  "tenantId": "495fc59f-96d9-4c3f-9c78-7a7b5f33d962",
  "user": {
    "name": "user@example.com",
    "type": "user"
  }
}
```

#### 1.3.4 OpenStack / OVH

1. In a dedicated temporary folder, create a file named `test_os.tf`
with the following content:
    ```hcl
    terraform {
      required_providers {
        openstack = {
          source  = "terraform-provider-openstack/openstack"
        }
      }
    }
    data "openstack_identity_auth_scope_v3" "scope" {
      name = "my_scope"
    }
    ```
2. In a terminal, move to where the file is located, then:
    ```shell
    terraform init
    ```
3. Finally, test terraform communication with OpenStack:
    ```
    terraform plan
    ```
    If everything is configured properly, terraform will output:
    ``` 
    No changes. Your infrastructure matches the configuration.
    ```
    Otherwise, it will output:
    ```
    Error: Error creating OpenStack identity client:
    ```
    if the OpenStack cloud API cannot be reached.
4. You can delete the temporary folder and its content.

### 1.4 Quotas

#### 1.4.1 AWS

The default quotas set by Amazon are sufficient to build the Magic Castle
AWS examples. To increase the limits, or request access to special
resources like GPUs or high performance network interface, refer to
[Amazon EC2 service quotas](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-resource-limits.html).

#### 1.4.2 Google Cloud

The default quotas set by Google Cloud are sufficient to build the Magic Castle
GCP examples. To increase the limits, or request access to special
resources like GPUs, refer to
[Google Compute Engine Resource quotas](https://cloud.google.com/compute/quotas).

#### 1.4.3 Microsoft Azure

The default quotas set by Microsoft Azure are sufficient to build the Magic Castle
Azure examples. To increase the limits, or request access to special
resources like GPUs or high performance network interface, refer to
[Azure subscription and service limits, quotas, and constraints](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/azure-subscription-service-limits).

#### 1.4.4 OpenStack

Minimum project requirements:
* 1 floating IP
* 3 security groups
* 1 network (see note 1)
* 1 subnet (see note 1)
* 1 router (see note 1)
* 3 volumes
* 3 instances
* 8 VCPUs
* 7 neutron ports
* 12 GB of RAM
* 8 security rules
* 80 GB of volume storage

**Note 1**: Magic Castle supposes the OpenStack project comes with a network, a subnet and a router already initialized. If any of these components is missing, you will need to create them manually before launching terraform.
* [Create and manager networks, JUSUF user documentation](https://apps.fz-juelich.de/jsc/hps/jusuf/cloud/first_steps_cloud.html?highlight=dns#create-and-manage-networks)
* [Create and manage network - UI, OpenStack Documentation](https://docs.openstack.org/horizon/latest/user/create-networks.html)
* [Create and manage network - CLI, OpenStack Documentation](https://docs.openstack.org/ocata/user-guide/cli-create-and-manage-networks.html)

#### 1.4.5 OVH

The default quotas set by OVH are sufficient to build the Magic Castle
OVH examples. To increase the limits, or request access to special
resources like GPUs, refer to
[OVHcloud - Increasing Public Cloud quotas](https://docs.ovh.com/ca/en/public-cloud/increase-public-cloud-quota/).

### 1.5 ssh-agent

To transfer configuration files, Terraform will connect to your cluster using SSH.
To avoid providing your private key to Terraform directly, you will have to
add it to the authentication agent, ssh-agent.

To learn how to start ssh-agent and add keys, refer to
[ssh-agent - How to configure, forwarding, protocol](https://www.ssh.com/academy/ssh/agent).

**Note 1**: If you own more than one key pair, make sure the private key added to
ssh-agent corresponds to the public key that will be granted access to your cluster
(refer to [section 4.9 public_keys](#49-public_keys)).

**Note 2**: If you have no wish to use ssh-agent, you can configure Magic Castle to
generate a key pair specific to your cluster. The public key will be written in
the sudoer `authorized_keys` and Terraform will be able to connect the cluster
using the corresponding private key. For more information,
refer to [section 4.15 generate_ssh_key](#415-generate_ssh_key-optional).

## 2. Cloud Cluster Architecture Overview

![Magic Castle Service Architecture](https://docs.google.com/drawings/d/e/2PACX-1vRGFtPevjgM0_ZrkIBQY881X73eQGaXDJ1Fb48Z0DyOe61h2dYdw0urWF2pQZWUTdcNSAM868sQ2Sii/pub?w=1259&amp;h=960)

## 3. Initialization

### 3.1 Main File

1. Go to https://github.com/ComputeCanada/magic_castle/releases.
2. Download the latest release of Magic Castle for your cloud provider.
3. Open a Terminal.
4. Uncompress the release: `tar xvf magic_castle*.tar.gz`
5. Rename the release folder after your favourite superhero: `mv magic_castle* hulk`
3. Move inside the folder: `cd hulk`

The file `main.tf` contains Terraform modules and outputs. Modules are files that define a set of
resources that will be configured based on the inputs provided in the module block.
Outputs are used to tell Terraform which variables of
our module we would like to be shown on the screen once the resources have been instantiated.

This file will be our main canvas to design our new clusters. As long as the module block
parameters suffice to our need, we will be able to limit our configuration to this sole
file. Further customization will be addressed during the second part of the workshop.

### 3.2 Terraform

Terraform fetches the plugins required to interact with the cloud provider defined by
our `main.tf` once when we initialize. To initialize, enter the following command:
```
terraform init
```

The initialization is specific to the folder where you are currently located.
The initialization process looks at all `.tf` files and fetches the plugins required
to build the resources defined in these files. If you replace some or all
`.tf` files inside a folder that has already been initialized, just call the command
again to make sure you have all plugins.

The initialization process creates a `.terraform` folder at the root of your current
folder. You do not need to look at its content for now.

#### 3.2.1 Terraform Modules Upgrade

Once Terraform folder has been initialized, it is possible to fetch the newest version
of the modules used by calling:
```
terraform init -upgrade
```

## 4. Configuration

In the `main.tf` file, there is a module named after your cloud provider,
i.e.: `module "openstack"`. This module corresponds to the high-level infrastructure
of your cluster.

The following sections describes each variable that can be used to customize
the deployed infrastructure and its configuration. Optional variables can be
absent from the example module. The order of the variables does not matter,
but the following sections are ordered as the variables appear in the examples.

### 4.1 source

The first line of the module block indicates to Terraform where it can find
the files that define the resources that will compose your cluster.
In the releases, this variable is a relative path to the cloud
provider folder (i.e.: `./aws`).

**Requirement**: Must be a path to a local folder containing the Magic Castle
Terraform files for the cloud provider of your choice. It can also be a git
repository. Refer to [Terraform documentation on module source](https://www.terraform.io/language/modules/sources#generic-git-repository) for more information.

**Post build modification effect**: `terraform init` will have to be
called again and the next `terraform apply` might propose changes if the infrastructure
describe by the new module is different.

### 4.2 config_git_url

Magic Castle configuration management is handled by
[Puppet](https://en.wikipedia.org/wiki/Puppet_(software)). The Puppet
configuration files are stored in a git repository. This is
typically [ComputeCanada/puppet-magic_castle](https://www.github.com/ComputeCanada/puppet-magic_castle) repository on GitHub.

Leave this variable to its current value to deploy a vanilla Magic Castle cluster.

If you wish to customize the instances' role assignment, add services, or
develop new features for Magic Castle, fork the [ComputeCanada/puppet-magic_castle](https://www.github.com/ComputeCanada/puppet-magic_castle) and point this variable to
your fork's URL. For more information on Magic Castle puppet configuration
customization, refer to [MC developer documentation](developers.md).

**Requirement**: Must be a valid HTTPS URL to a git repository describing a
Puppet environment compatible with [Magic Castle](developers.md). If the repo
is private, generate an access token with a permission to read the repo content,
and provide the token in the `config_git_url` like this:
```
config_git_url = "https://oauth2:${oauth-key-goes-here}@domain.com/username/repo.git"
```
This works for GitHub and GitLab (including community edition).

**Post build modification effect**: no effect. To change the Puppet configuration source,
destroy the cluster or change it manually on the Puppet server.

### 4.3 config_version

Since Magic Cluster configuration is managed with git, it is possible to specify
which version of the configuration you wish to use. Typically, it will match the
version number of the release you have downloaded (i.e: `9.3`).

**Requirement**: Must refer to a git commit, tag or branch existing
in the git repository pointed by `config_git_url`.

**Post build modification effect**: none. To change the Puppet configuration version,
destroy the cluster or change it manually on the Puppet server.

### 4.4 cluster_name

Defines the `ClusterName` variable in `slurm.conf` and the name of
the cluster in the Slurm accounting database
([see `slurm.conf` documentation](https://slurm.schedmd.com/slurm.conf.html)).

**Requirement**: Must be lowercase alphanumeric characters and start with a letter. It can include dashes. cluster_name must be 40 characters or less.

**Post build modification effect**: destroy and re-create all instances at next `terraform apply`.

### 4.5 domain

Defines
* the Kerberos realm name when initializing FreeIPA.
* the internal domain name and the `resolv.conf` search domain as
`int.{cluster_name}.{domain}`

Optional modules following the current module in the example `main.tf` can
be used to register DNS records in relation to your cluster if the
DNS zone of this domain is administered by one of the supported providers.
Refer to section [6. DNS Configuration and SSL Certificates](#6-dns-configuration-and-wildcard-ssl-certificate)
for more details.

**Requirements**:

- Must be a fully qualified DNS name and [RFC-1035-valid](https://tools.ietf.org/html/rfc1035).
Valid format is a series of labels 1-63 characters long matching the
regular expression `[a-z]([-a-z0-9]*[a-z0-9])`, concatenated with periods.
- No wildcard record A of the form `*.domain. IN A x.x.x.x` exists for that
domain. You can verify no such record exist with `dig`:
    ```
    dig +short '*.${domain}'
    ```

**Post build modification effect**: destroy and re-create all instances at next `terraform apply`.

### 4.6 image

Defines the name of the image that will be used as the base image for the cluster nodes.

You can use a custom image if you wish, but configuration management
should be mainly done through Puppet. Image customization is mostly
envisioned as a way to accelerate the configuration process by applying the
security patches and OS updates in advance.

To specify a different image for an instance type, use the
[`image` instance attribute](#472-optional-attributes)

**Requirements**: the operating system on the image must be from the RedHat family.
This includes CentOS (7, 8), Rocky Linux (8), and AlmaLinux (8).

**Post build modification effect**: none. If this variable is modified, existing
instances will ignore the change and future instances will use the new value.

#### 4.6.1 AWS

The image field needs to correspond to the Amazon Machine Image (AMI) ID.
AMI IDs are specific to regions and architectures. Make sure to use the
right ID for the region and CPU architecture you are using (i.e: x86_64).

To find out which AMI ID you need to use, refer to
- [AlmaLinux OS Amazon Web Services AMIs](https://wiki.almalinux.org/cloud/AWS.html#community-amis)
- [CentOS list of official images available on the AWS Marketplace](https://www.centos.org/download/aws-images/)
- [Rocky Linux](https://rockylinux.org/cloud-images/)

**Note**: Before you can use the AMI, you will need to accept the usage terms
and subscribe to the image on AWS Marketplace. On your first deployment,
you will be presented an error similar to this one:
```
│ Error: Error launching source instance: OptInRequired: In order to use this AWS Marketplace product you need to accept terms and subscribe. To do so please visit https://aws.amazon.com/marketplace/pp?sku=cvugziknvmxgqna9noibqnnsy
│ 	status code: 401, request id: 1f04a85a-f16a-41c6-82b5-342dc3dd6a3d
│
│   on aws/infrastructure.tf line 67, in resource "aws_instance" "instances":
│   67: resource "aws_instance" "instances" {
```
To accept the terms and fix the error, visit the link provided in the error output,
then click on the `Click to Subscribe` yellow button.

#### 4.6.2 Microsoft Azure

The image field for Azure can either be a string or a map.

A string image specification will correspond to the image id. Image ids
can be retrieved using the following command-line:
```
az image builder list
```

A map image specification needs to contain the following
fields `publisher`, `offer` `sku`, and optionally `version`.
The map is used to specify images found in [Azure Marketplace](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/cli-ps-findimage).
Here is an example:
```
{
    publisher = "OpenLogic",
    offer     = "CentOS-CI",
    sku       = "7-CI"
}
```

#### 4.6.3 OpenStack

The image name can be a regular expression. If more than one image is returned by the query
to OpenStack, the most recent is selected.

### 4.7 instances

The `instances` variable is a map that defines the virtual machines that will form
the cluster. The map' keys define the hostnames and the values are the attributes
of the virtual machines.

Each instance is identified by a unique hostname. An instance's hostname is written as
the key followed by its index (1-based). The following map:
```hcl
instances = {
  mgmt     = { type = "p2-4gb", tags = [...] },
  login    = { type = "p2-4gb",     count = 1, tags = [...] },
  node     = { type = "c2-15gb-31", count = 2, tags = [...] },
  gpu-node = { type = "gpu2.large", count = 3, tags = [...] },
}
```
will spawn instances with the following hostnames:
```
mgmt1
login1
node1
node2
gpu-node1
gpu-node2
gpu-node3
```

Hostnames must follow a set of rules, from `hostname` man page:
> Valid characters for hostnames are ASCII letters from a to z,
the digits from 0 to 9, and the hyphen (-). A hostname may not start with a hyphen.

Two attributes are expected to be defined for each instance:
1. `type`: name for varying combinations of CPU, memory, GPU, etc. (i.e: `t2.medium`);
2. `tags`: list of labels that defines the role of the instance.

#### 4.7.1 tags

Tags are used in the Terraform code to identify if devices (volume, network) need to be attached to an
instance, while in Puppet code tags are used to identify roles of the instances.

Terraform tags:
- `login`: identify instances accessible with SSH from Internet and pointed by the domain name A records
- `pool`: identify instances created only when their hostname appears in the [`var.pool`](#417-pool-optional) list.
- `proxy`: identify instances accessible with HTTP/HTTPS and pointed by the vhost A records
- `public`: identify instances that need to have a public ip address reachable from Internet
- `puppet`: identify instances configured as Puppet servers
- `spot`: identify instances that are to be spawned as spot/preemptible instances.
This tag is supported in AWS, Azure and GCP. It is ignored by OpenStack and OVH.
- `efa`: attach an Elastic Fabric Adapter network interface to the instance. This tag is supported in AWS.
- `ssl`: identify instances that receive a copy of the SSL wildcard certificate for the domain

Puppet tags expected by the [puppet-magic_castle](https://www.github.com/ComputeCanada/puppet-magic_castle) environment.
- `login`: identify a login instance (minimum: 2 CPUs, 2GB RAM)
- `mgmt`: identify a management instance i.e: FreeIPA server, Slurm controller, Slurm DB (minimum: 2 CPUs, 6GB RAM)
- `nfs`: identify the instance that acts as an NFS server.
- `node`: identify a compute node instance (minimum: 1 CPUs, 2GB RAM)
- `pool`: when combined with `node`, it identifies compute nodes that Slurm can resume/suspend to meet workload demand.
- `proxy`: identify the instance that executes the Caddy reverse proxy and JupyterHub.

In the Magic Castle Puppet environment, an instance cannot be tagged as `mgmt` and `proxy`.

You are free to define your own additional tags.

#### 4.7.2 Optional attributes

Optional attributes can be defined:
1. `count`: number of virtual machines with this combination of hostname prefix, type and tags to create (default: 1).
2. `image`: specification of the image to use for this instance type. (default: global [`image`](#46-image) value).
Refer to section [10.12 - Create a compute node image](#1012-create-a-compute-node-image) to learn how this attribute can
be leveraged to accelerate compute node configuration.
3. `disk_size`: size in gibibytes (GiB) of the instance's root disk containing
the operating system and service software
(default: see the next table).
4. `disk_type`: type of the instance's root disk (default: see the next table).

Default root disk's attribute value per provider:
| Provider | `disk_type` | `disk_size` (GiB) |
| -------- | :---------- | ----------------: |
| Azure    |`Premium_LRS`| 30                |
| AWS      | `gp2`       | 10                |
| GCP      | `pd-ssd`    | 20                |
| OpenStack| `null`      | 10                |
| OVH      | `null`      | 10                |

For some cloud providers, it possible to define additional attributes.
The following sections present the available attributes per provider.

##### AWS

For instances with the `spot` tags, these attributes can also be set:
- `wait_for_fulfillment` (default: true)
- `spot_type` (default: permanent)
- `instance_interruption_behavior` (default: stop)
- `spot_price` (default: not set)
- `block_duration_minutes` (default: not set) [note 1]
For more information on these attributes, refer to
[`aws_spot_instance_request` argument reference](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/spot_instance_request#argument-reference)

**Note 1**: `block_duration_minutes` is not available to new AWS accounts
or accounts without billing history -
[AWS EC2 Spot Instance requests](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/spot-requests.html#fixed-duration-spot-instances). When not available, its usage can trigger
quota errors like this:
``` 
Error requesting spot instances: MaxSpotInstanceCountExceeded: Max spot instance count exceeded
```

##### Azure

For instances with the `spot` tags, these attributes can also be set:
- `max_bid_price` (default: not set)
- `eviction_policy` (default: `Deallocate`)
For more information on these attributes, refer to
[`azurerm_linux_virtual_machine` argument reference](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_virtual_machine#argument-reference)

##### GCP

- `gpu_type`: name of the GPU model to attach to the instance. Refer to
[Google Cloud documentation](https://cloud.google.com/compute/docs/gpus) for the list of
available models per region
- `gpu_count`: number of GPUs of the `gpu_type` model to attach to the instance

#### 4.7.3 Post build modification effect

Modifying any part of the map after the cluster is built will only affect
the type of instances associated with what was modified at the
next `terraform apply`.

### 4.8 volumes

The `volumes` variable is a map that defines the block devices that should be attached
to instances that have the corresponding key in their list of tags. To each instance
with the tag, unique block devices are attached, no multi-instance attachment is supported.

Each volume in map is defined a key corresponding to its and a map of attributes:
- `size`: size of the block device in GB.
- `type` (optional): type of volume to use. Default value per provider:
  - Azure: `Premium_LRS`
  - AWS: `gp2`
  - GCP: `pd-ssd`
  - OpenStack: `null`
  - OVH: `null`

Volumes with a tag that have no corresponding instance will not be created.

In the following example:
```hcl
instances = { 
  server = { type = "p4-6gb", tags = ["nfs"] }
}
volumes = {
  nfs = {
    home = { size = 100 }
    project = { size = 100 }
    scratch = { size = 100 }
  }
  mds = {
    oss1 = { size = 500 }
    oss2 = { size = 500 }
  }
}
```

The instance `server1` will have three volumes attached to it. The volumes tagged `mds` are
not created since no instances have the corresponding tag.

To define an infrastructure with no volumes, set the `volumes` variable to an empty map:
```hcl
volumes = {}
```

**Post build modification effect**: destruction of the corresponding volumes and attachments,
and creation of new empty volumes and attachments. If an no instance with a corresponding tag
exist following modifications, the volumes will be deleted.

### 4.9 public_keys

List of SSH public keys that will have access to your cluster sudoer account.

**Note 1**: You need to add the private key associated with one of the public
keys to your local authentication agent (i.e: `ssh-add`) for Terraform to be
able to copy Puppet configuration files with scp on the cluster. Otherwise,
Magic Castle can create a key pair for unique to this cluster, see section
[4.15 - generate_ssh_key (optional)](#415-generate_ssh_key-optional).

**Post build modification effect**: trigger scp of hieradata files at next `terraform apply`.
The sudoer account `authorized_keys` file will be updated by each instance's Puppet agent
following the copy of the hieradata files.

### 4.10 nb_users (optional)

**default value**: 0

Defines how many guest user accounts will be created in
FreeIPA. Each user account shares the same randomly generated password.
The usernames are defined as `userX` where `X` is a number between 1 and
the value of `nb_users` (zero-padded, i.e.: `user01 if X < 100`, `user1 if X < 10`).

If an NFS NFS `home` volume is defined, each user will have a home folder
on a shared NFS storage hosted on the NFS server node.

User accounts do not have sudoer privileges. If you wish to use `sudo`,
you will have to login using the sudoer account and the SSH keys listed
in `public_keys`.

If you would like to add a user account after the cluster is built, refer to
section [10.3](#103-add-ldap-users) and [10.4](#104-increase-the-number-of-guest-accounts).

**Requirement**: Must be an integer, minimum value is 0.

**Post build modification effect**: trigger scp of hieradata files at next `terraform apply`.
If `nb_users` is increased, new guest accounts will be created during the following
Puppet run on `mgmt1`. If `nb_users` is decreased, it will have no effect: the guest accounts
already created will be left intact.

### 4.11 guest_passwd (optional)

**default value**: 4 random words separated by dots

Defines the password for the guest user accounts instead of using a
randomly generated one.

**Requirement**: Minimum length **8 characters**.

The password can be provided in a PKCS7 encrypted form. Refer to sub-section
[4.13.1 Encrypting hieradata secrets](#4131-encrypting-hieradata-secrets)
for instructions on how to encrypt the password.

**Post build modification effect**: trigger scp of hieradata files at next `terraform apply`.
Password of all guest accounts will be changed to match the new password value.

### 4.12 sudoer_username (optional)

**default value**: `centos`

Defines the username of the account with sudo privileges. The account
ssh authorized keys are configured with the SSH public keys with
`public_keys`.

**Post build modification effect**: none. To change sudoer username,
destroy the cluster or redefine the value of
[`profile::base::sudoer_username`](https://github.com/computecanada/puppet-magic_castle#profilebase)
in `hieradata`.

### 4.13 hieradata (optional)

**default value**: empty string

Defines custom variable values that are injected in the Puppet hieradata file.
Useful to override common configuration of Puppet classes.

List of useful examples:
- Receive logs of Puppet runs with changes to your email, add the
following line to the string:
    ```yaml
    profile::base::admin_email: "me@example.org"
    ```
- Define ip addresses that can never be banned by fail2ban:
    ```yaml
    profile::fail2ban::ignore_ip: ['132.203.0.0/16', '8.8.8.8']
    ```
- Remove one-time password field from JupyterHub login page:
    ```yaml
    jupyterhub::enable_otp_auth: false
    ```

Refer to the following Puppet modules' documentation to know more about the key-values that can be defined:
- [puppet-magic_castle](https://github.com/ComputeCanada/puppet-magic_castle/blob/main/README.md)
- [puppet-jupyterhub](https://github.com/ComputeCanada/puppet-jupyterhub/blob/main/README.md#hieradata-configuration)


The file created from this string can be found on `puppet` as
```
/etc/puppetlabs/data/user_data.yaml
```

**Requirement**: The string needs to respect the [YAML syntax](https://en.wikipedia.org/wiki/YAML#Syntax).

**Post build modification effect**: trigger scp of hieradata files at next `terraform apply`.
Each instance's Puppet agent will be reloaded following the copy of the hieradata files.

#### 4.13.1. Encrypting hieradata secrets

If you plan to track the cluster configuration files in git (i.e:`main.tf`, `user_data.yaml`),
it would be a good idea to encrypt the sensitive property values.

Magic Castle uses [Puppet hiera-eyaml](https://github.com/voxpupuli/hiera-eyaml) to provide a
per-value encryption of sensitive properties to be used by Puppet.

To encrypt the data, you need to access the eyaml public certificate file of your cluster.
This file is located on the Puppet server at `/etc/puppetlabs/puppet/eyaml/public_key.pkcs7.pem`.
With the public certificate file, you can encrypt the values with eyaml:
```sh
/opt/puppetlabs/puppet/bin/eyaml encrypt -s 'your-secret' --pkcs7-public-key /etc/puppetlabs/puppet/eyaml/public_key.pkcs7.pem -o string
```

You can encrypt the value remotely using SSH jump host:
```sh
ssh -J centos@your-cluster.yourdomain.cloud centos@puppet /opt/puppetlabs/puppet/bin/eyaml encrypt -s 'your-secret' --pkcs7-public-key=/etc/puppetlabs/puppet/eyaml/public_key.pkcs7.pem -o string
```

The openssl command-line can also be used to encrypt a value with the certificate file:
```sh
echo 'your-secret' |  openssl smime -encrypt -aes-256-cbc -outform der public_key.pkcs7.pem | base64 | xargs printf "ENC['PKCS7,%s']\n"
```

To learn more about `public_key.pkcs7.pem` and how it can be generated before the cluster creation, refer to
section [10.13 Generate and replace Puppet hieradata encryption keys](#1013-generate-and-replace-puppet-hieradata-encryption-keys).

### 4.14 firewall_rules (optional)

**default value**:
```hcl
{
  ssh     = { "from_port" = 22,    "to_port" = 22,    tag = "login", "protocol" = "tcp", "cidr" = "0.0.0.0/0" },
  http    = { "from_port" = 80,    "to_port" = 80,    tag = "proxy", "protocol" = "tcp", "cidr" = "0.0.0.0/0" },
  https   = { "from_port" = 443,   "to_port" = 443,   tag = "proxy", "protocol" = "tcp", "cidr" = "0.0.0.0/0" },
  globus  = { "from_port" = 2811,  "to_port" = 2811,  tag = "dtn",   "protocol" = "tcp", "cidr" = "54.237.254.192/29" },
  myproxy = { "from_port" = 7512,  "to_port" = 7512,  tag = "dtn",   "protocol" = "tcp", "cidr" = "0.0.0.0/0" },
  gridftp = { "from_port" = 50000, "to_port" = 51000, tag = "dtn",   "protocol" = "tcp", "cidr" = "0.0.0.0/0" }
}
```

Defines a map of firewall rules that control external traffic to the public nodes. Each rule is
defined as a map of key-value pairs and has to be assigned a unique name:
- `from_port` (req.):  the lower part of the allowed port range, valid integer value needs to be between 1 and 65535.
- `to_port` (req.): the higher part of the allowed port range, valid integer value needs to be between 1 and 65535.
- `tag` (req.): instances with this tag will be assigned this firewall rule.
- `ethertype` (opt. default: `"IPv4"`): the layer 3 protocol type (`"IPv4"` or `"IPv6"`).
- `protocol` (opt. default: `"tcp"`): the layer 4 protocol type.
- `cidr` (opt. default: `"0.0.0.0/0"`): the remote CIDR, the value needs to be a valid CIDR (i.e. `192.168.0.0/16`).

If you would like Magic Castle to be able to transfer files and update the state of the cluster in Puppet, make
sure there exists at least one effective firewall rule where `from_port <= 22 <= to_port` and for which the external
IP address of the machine that executes Terraform is in the CIDR range (i.e: `cidr = "0.0.0.0/0"` being the most
permissive). This corresponds to the `ssh` rule in the default firewall rule map.
This guarantees that Terraform will be able to use SSH to connect to the cluster from anywhere. For more information
about this requirement, refer to Magic Castle's
[bastion tag computation code](https://github.com/ComputeCanada/magic_castle/blob/main/common/design/main.tf#L58).

**Post build modification effect**: modify the cloud provider firewall rules at next `terraform apply`.

### 4.15 generate_ssh_key (optional)

**default_value**: `false`

If true, Terraform will generate an ssh key pair that would then be used when copying file with Terraform
file-provisioner. The public key will be added to the sudoer account authorized keys.

This parameter is useful when Terraform does not have access to one of the private key associated with the
public keys provided in `public_keys`.

**Post build modification effect**:
- `false` -> `true`: will cause Terraform failure.
Terraform will try to use the newly created private SSH key
to connect to the cluster, while the corresponding public SSH
key is yet registered with the sudoer account.
- `true` -> `false`: will trigger a scp of terraform_data.yaml at
next terraform apply. The Terraform public SSH key will be removed
from the sudoer account `authorized_keys` file at next
Puppet agent run.

### 4.16 software_stack (optional)

**default_value**: `"alliance"`

Defines the scientific software environment that users have access when they login.
Possible values are:
- **default** - `"alliance"` / `"computecanada"`: [Digital Alliance Research Alliance of Canada scientific software environment](https://docs.alliancecan.ca/wiki/Accessing_CVMFS) (previously Compute Canada environment)
- `"eessi"`: [European Environment for Scientific Software Installation (EESSI)](https://eessi.github.io/docs/)
- `null` / `""`: no scientific software environment

**Post build modification effect**: trigger scp of hieradata files at next `terraform apply`.

### 4.17 pool (optional)

**default_value**: `[]`

Defines a list of hostnames with the tag `"pool"` that have to be online. This variable is typically
managed by the workload scheduler through Terraform API. For more information, refer to
[Enable Magic Castle Autoscaling](terraform_cloud.md#enable-magic-castle-autoscaling)

**Post build modification effect**: `pool` tagged hosts with name present in the list
will be instantiated, others will stay uninstantiated or will be destroyed
if previously instantiated.

### 4.18 skip_upgrade (optional)

**default_value** = `false`

Determines whether the base image packages will be upgraded during the first boot or not. By default,
all packages are upgraded. If `skip_upgrade` set to `true`, no package will be upgraded on first boot.

**Post build modification effect**: No effect on currently built instances. Ones created
after the modification will take into consideration the new value of the parameter to determine
whether they should upgrade the base image packages or not.

### 4.19 puppetfile (optional)

**default_value** = `""`

Defines a complement of modules to install with librarian puppet when initializing the Puppet environment
on the first boot of the Puppet server. If the provided string include the
[`forge` setting](https://www.puppet.com/docs/pe/2019.8/puppetfile.html#declare_puppet_forge_modules_in_the_puppetfile),
the provided content will replace entirely the Magic Castle environment's
[Puppetfile](https://github.com/ComputeCanada/puppet-magic_castle/blob/main/Puppetfile).

**Post build modification effect**: None. To modify the Puppetfile after the cluster is initialized, log
on the Puppet server and modify `/etc/puppetlabs/code/environments/production/Puppetfile`.

## 5. Cloud Specific Configuration

### 5.1 Amazon Web Services

#### 5.1.1 region

Defines the label of the AWS EC2 region where the cluster will be created (i.e.: `us-east-2`).

**Requirement**: Must be in the [list of available EC2 regions](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html#concepts-available-regions).

**Post build modification effect**: rebuild of all resources at next `terraform apply`.

#### 5.1.2 availability_zone (optional)

**default value**: None

Defines the label of the data center inside the AWS region where the cluster will be created (i.e.: `us-east-2a`).
If left blank, it chosen at random amongst the availability zones of the selected region.

**Requirement**: Must be in a valid availability zone for the selected region. Refer to
[AWS documentation](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html#using-regions-availability-zones-describe)
to find out how list the availability zones.

### 5.2 Microsoft Azure

#### 5.2.1 location

Defines the label of the Azure location where the cluster will be created (i.e.: `eastus`).

**Requirement**: Must be a valid Azure location. To get the list of available location, you can
use Azure CLI : `az account list-locations -o table`.

**Post build modification effect**: rebuild of all resources at next `terraform apply`.

#### 5.2.2 azure_resource_group (optional)

**default value**: None

Defines the name of an already created resource group to use. Terraform
will no longer attempt to manage a resource group for Magic Castle if
this variable is defined and will instead create all resources within
the provided resource group. Define this if you wish to use an already
created resource group or you do not have a subscription-level access to
create and destroy resource groups.

**Post build modification effect**: rebuild of all instances at next `terraform apply`.

#### 5.2.3 plan (optional)

**default value**:
```hcl
{
  name      = null
  product   = null
  publisher = null
}
```

Purchase plan information for Azure Marketplace image. Certain images from Azure Marketplace
requires a terms acceptance or a fee to be used. When using this kind of image, you must supply
the plan details.

For example, to use the official [AlmaLinux image](https://azuremarketplace.microsoft.com/en-us/marketplace/apps/almalinux.almalinux-x86_64?tab=Overview), you have to first add it to your
account. Then to use it with Magic Castle, you must supply the following plan information:
```
plan = {
  name      = "8_7"
  product   = "almalinux"
  publisher = "almalinux"
}
```

### 5.3 Google Cloud

#### 5.3.1 project

Defines the label of the unique identifier associated with the Google Cloud project in which the resources will be created.
It needs to corresponds to GCP project ID, which is composed of the project name and a randomly
assigned number.

**Requirement**: Must be a valid Google Cloud project ID.

**Post build modification effect**: rebuild of all resources at next `terraform apply`.

#### 5.3.2 region

Defines the name of the specific geographical location where the cluster resources will be hosted.

**Requirement**: Must be a valid Google Cloud region. Refer to [Google Cloud documentation](https://cloud.google.com/compute/docs/regions-zones#available)
for the list of available regions and their characteristics.

#### 5.3.3 zone (optional)

**default value**: None

Defines the name of the zone within the region where the cluster resources will be hosted.

**Requirement**: Must be a valid Google Cloud zone. Refer to [Google Cloud documentation](https://cloud.google.com/compute/docs/regions-zones#available)
for the list of available zones and their characteristics.

### 5.4 OpenStack and OVH

#### 5.4.1 os_floating_ips (optional)

**default value**: `{}`

Defines a map as an association of instance names (key) to
pre-allocated floating ip addresses (value). Example:
```
  os_floating_ips = {
    login1 = 132.213.13.59
    login2 = 132.213.13.25
  }
```
- instances tagged as public that have an entry in this map will be assigned
the corresponding ip address;
- instances tagged as public that do not have an entry in this map will be assigned
a floating ip managed by Terraform.
- instances not tagged as public that have an entry in this map will
not be assigned a floating ip.

This variable can be useful if you manage your DNS manually and
you would like the keep the same domain name for your cluster at each
build.

**Post build modification effect**: change the floating ips assigned
to the public instances.

#### 5.4.2 os_ext_network (optional)

**default value**: None

Defines the name of the external network that provides the floating
ips. Define this only if your OpenStack cloud provides multiple
external networks, otherwise, Terraform can find it automatically.

**Post build modification effect**: change the floating ips assigned to the public nodes.

#### 5.4.4 subnet_id (optional)

**default value**: None

Defines the ID of the internal IPV4 subnet to which the instances are
connected. Define this if you have or intend to have more than one
subnets defined in your OpenStack project. Otherwise, Terraform can
find it automatically. Can be used to force a v4 subnet when both v4 and v6 exist.

**Post build modification effect**: rebuild of all instances at next `terraform apply`.

## 6. DNS Configuration and Wildcard SSL Certificate

Some functionalities in Magic Castle require the registration of DNS records under the
[cluster name](#44-cluster_name) in the selected [domain](#45-domain). This includes
web services like JupyterHub, Mokey and FreeIPA web portal.

If your domain DNS records are managed by one of the supported providers,
follow the instructions in the corresponding sections to have the cluster's
DNS records created and tracked by Magic Castle.

If your DNS provider is not supported, you can manually create the records.
Refer to the subsection [6.3](#63-unsupported-providers) for more details.

Optionally, Magic Castle can issue with [Let's encrypt DNS-01 challenge](https://letsencrypt.org/docs/challenge-types/#dns-01-challenge)
a wildcard certificate of the form `*.${cluster_name}.${domain_name}`. Refer to
the subsection [6.4](#64-wildcard-ssl-certificate) for more information. If no wildcard certificate is issued,
the reverse proxy server Caddy will automatically issue one certificate per virtual
host.

### 6.1 Cloudflare

1. Uncomment the `dns` module for Cloudflare in your `main.tf`.
2. Uncomment the `output "hostnames"` block.
3. Download and install the Cloudflare Terraform module: `terraform init`.
4. Export the environment variables `CLOUDFLARE_EMAIL` and `CLOUDFLARE_API_KEY`, where `CLOUDFLARE_EMAIL` is your Cloudflare account email address and `CLOUDFLARE_API_KEY` is your account Global API Key available in your [Cloudflare profile](https://dash.cloudflare.com/profile/api-tokens).

#### 6.1.2 Cloudflare API Token

If you prefer using an API token instead of the global API key, you will need to configure a token with the following four permissions with the [Cloudflare API Token interface](https://dash.cloudflare.com/profile/api-tokens).

| Section | Subsection | Permission|
| :------ |:---------- | :-------- |
| Zone    | DNS        | Edit      |

Instead of step 5, export only `CLOUDFLARE_API_TOKEN`, `CLOUDFLARE_ZONE_API_TOKEN`, and `CLOUDFLARE_DNS_API_TOKEN` equal to the API token generated previously.

### 6.2 Google Cloud

**requirement**: Install the [Google Cloud SDK](https://cloud.google.com/sdk/docs/downloads-interactive)

1. Login to your Google account with gcloud CLI : `gcloud auth application-default login`
2. Uncomment the `dns` module for Google Cloud in your `main.tf`.
3. Uncomment the `output "hostnames"` block.
4. In `main.tf`'s `dns` module, configure the variables `project` and `zone_name`
with their respective values as defined by your Google Cloud project.
5. Download and install the Google Cloud Terraform module: `terraform init`.

### 6.3 Unsupported providers

If your DNS provider is not currently supported by Magic Castle, you can create the DNS records manually.

Magic Castle provides a module that creates a text file with the DNS records that can
then be imported manually in your DNS zone. To use this module, add the following
snippet to your `main.tf`:

```hcl
module "dns" {
    source           = "./dns/txt"
    name             = module.openstack.cluster_name
    domain           = module.openstack.domain
    public_instances = module.openstack.public_instances
}
```

Find and replace `openstack` in the previous snippet by your cloud provider of choice
if not OpenStack (i.e: `aws`, `gcp`, etc.).

The file will be created after the `terraform apply` in the same folder as your `main.tf`
and will be named as `${name}.${domain}.txt`.

### 6.4 Wildcard SSL Certificate

**Requirement**: A private key associated with one of the
[public keys](#49-public_keys) needs to be tracked (i.e: `ssh-add`) by the local
[authentication agent](https://www.ssh.com/ssh/agent) (i.e: `ssh-agent`).
This module uses the ssh-agent tracked SSH keys to authenticate and
to copy SSL certificate files to the proxy nodes after their creation.

To issue a wildcard SSL certificate with Magic Castle, modify the dns module call
in your `main.tf` like this:
1. add the input: `issue_wildcard_cert = true`
2. add the input: `email = "replace.by@your.email"`

#### 6.4.1 ACME Account Private Key

To create the wildcard SSL certificate associated with the domain name, Magic Castle
creates a private key and register a new ACME account with this key. This account
registration process is done for each new cluster. However, ACME limits the number of
new accounts that can be created to a maximum of 10 per IP Address per 3 hours.

If you plan to create more than 10 clusters per 3 hours, we recommend registering an
ACME account first and then provide its private key in PEM format to Magic Castle DNS
module, using the `acme_key_pem` variable.

##### How to Generate an ACME Account Private Key

In a separate folder, create a file with the following content
```hcl
terraform {
  required_version = ">= 1.2.1"
  required_providers {
    acme = {
      source = "vancluever/acme"
    }
    tls = {
      source = "hashicorp/tls"
    }
  }
}

variable "email" {}

provider "acme" {
  server_url = "https://acme-v02.api.letsencrypt.org/directory"
}
resource "tls_private_key" "private_key" {
  algorithm = "RSA"
}
resource "acme_registration" "reg" {
  account_key_pem = tls_private_key.private_key.private_key_pem
  email_address   = var.email
}
resource "local_file" "acme_key_pem" {
    content     = tls_private_key.private_key.private_key_pem
    filename = "acme_key.pem"
}
```

In the same folder, enter the following commands and follow the instructions:
```
terraform init
terraform apply
```

Once done, copy the file named `acme_key.pem` somewhere safe, and where you will be able
to refer to later on. Then, when the time comes to create a new cluster, add the following
variable to the DNS module in your `main.tf`:
```hcl
acme_key_pem = file("path/to/your/acme_key.pem")
```

#### 6.4.2 Issuing the wildcard SSL certificate manually

Magic Castle generates with Let's Encrypt a wildcard certificate for `*.cluster_name.domain`.
You can use [certbot](https://certbot.eff.org/docs/using.html#dns-plugins) DNS-01 challenge
plugin to generate the wildcard certificate.

You will then need to copy the certificate files in the proper location on each proxy node.
The reverse proxy configuration expects the following files to exist:
- `/etc/letsencrypt/live/${domain_name}/fullchain.pem`
- `/etc/letsencrypt/live/${domain_name}/privkey.pem`
- `/etc/letsencrypt/live/${domain_name}/chain.pem`

Refer to the [reverse proxy configuration](https://github.com/ComputeCanada/puppet-magic_castle/blob/main/site/profile/manifests/reverse_proxy.pp) for more details.

### 6.5 SSHFP records and DNSSEC

Magic Castle DNS module creates SSHFP records for all instances with a public ip address.
These records can be used by SSH clients to verify the SSH host keys of the server.
If [DNSSEC](https://developers.cloudflare.com/dns/dnssec/)
is enabled for the domain and the SSH client is correctly configured,
no host key confirmation will be prompted when connecting to the server.

For more information on how to activate DNSSEC, refer to your DNS provider documentation:
- [CloudFlare - Enable DNSSEC](https://developers.cloudflare.com/dns/dnssec/#enable-dnssec)
- [Google Cloud - Manage DNSSEC configuration](https://cloud.google.com/dns/docs/dnssec-config#enabling)

To setup an SSH client to use SSHFP records, add
```
VerifyHostKeyDNS yes
```
to its configuration file (i.e.: `~/.ssh/config`).

## 7. Planning

Once your initial cluster configuration is done, you can initiate
a planning phase where you will ask Terraform to communicate with
your cloud provider and verify that your cluster can be built as it is
described by the `main.tf` configuration file.

Terraform should now be able to communicate with your cloud provider.
To test your configuration file, enter the following command
```
terraform plan
```

This command will validate the syntax of your configuration file and
communicate with the provider, but it will not create new resources. It
is only a dry-run. If Terraform does not report any error, you can move
to the next step. Otherwise, read the errors and fix your configuration
file accordingly.

## 8. Deployment

To create the resources defined by your main, enter the following command
```
terraform apply
```

The command will produce the same output as the `plan` command, but after
the output it will ask for a confirmation to perform the proposed actions.
Enter `yes`.

Terraform will then proceed to create the resources defined by the
configuration file. It should take a few minutes. Once the creation process
is completed, Terraform will output the guest account usernames and password,
the sudoer username and the floating ip of the login
node.

**Warning**: although the instance creation process is finished once Terraform
outputs the connection information, you will not be able to
connect and use the cluster immediately. The instance creation is only the
first phase of the cluster-building process. The configuration: the
creation of the user accounts, installation of FreeIPA, Slurm, configuration
of JupyterHub, etc.; takes around 15 minutes after the instances are created.

Once it is booted, you can follow an instance configuration process by looking at:

* `/var/log/cloud-init-output.log`
* `journalctl -u puppet`

If unexpected problems occur during configuration, you can provide these
logs to the authors of Magic Castle to help you debug.

### 8.1 Deployment Customization

You can modify the `main.tf` at any point of your cluster's life and
apply the modifications while it is running.

**Warning**: Depending on the variables you modify, Terraform might destroy
some or all resources, and create new ones. The effects of modifying each
variable are detailed in the subsections of **Configuration**.

For example, to increase the number of computes nodes by one. Open
`main.tf`, add 1 to `node`'s `count` , save the document and call
```
terraform apply
```

Terraform will analyze the difference between the current state and
the future state, and plan the creation of a single new instance. If
you accept the action plan, the instance will be created, provisioned
and eventually automatically add to the Slurm cluster configuration.

You could do the opposite and reduce the number of compute nodes to 0.

## 9. Destruction

Once you're done working with your cluster and you would like to recover
the resources, in the same folder as `main.tf`, enter:
```
terraform destroy -refresh=false
```

The `-refresh=false` flag is to avoid an issue where one or many of the data
sources return no results and stall the cluster destruction with a message like
the following:
```
Error: Your query returned no results. Please change your search criteria and try again.
```
This type of error happens when for example the specified [image](#46-image)
no longer exists (see [issue #40](https://github.com/ComputeCanada/magic_castle/issues/40)).

As for `apply`, Terraform will output a plan that you will have to confirm
by entering `yes`.

**Warning**: once the cluster is destroyed, nothing will be left, even the
shared storage will be erased.

### 9.1 Instance Destruction

It is possible to destroy only the instances and keep the rest of the infrastructure
like the floating ip, the volumes, the generated SSH host key, etc. To do so, set
the count value of the instance type you wish to destroy to 0.

### 9.2 Reset

On some occasions, it is desirable to rebuild some of the instances from scratch.
Using `terraform taint`, you can designate resources that will be rebuilt at
next application of the plan.

To rebuild the first login node :
```
terraform taint 'module.openstack.openstack_compute_instance_v2.instances["login1"]'
terraform apply
```

## 10. Customize Cluster Software Configuration

Once the cluster is online and configured, you can modify its configuration as you see fit.
We list here how to do most commonly asked for customizations.

Some customizations are done from the Puppet server instance (`puppet`).
To connect to the puppet server, follow these steps:

1. Make sure your SSH key is loaded in your ssh-agent.
2. SSH in your cluster with forwarding of the authentication
agent connection enabled: `ssh -A centos@cluster_ip`.
Replace `centos` by the value of `sudoer_username` if it is
different.
3. SSH in the Puppet server instance: `ssh puppet`

**Note on Google Cloud**: In GCP, [OS Login](https://cloud.google.com/compute/docs/instances/managing-instance-access)
lets you use Compute Engine IAM roles to manage SSH access to Linux instances.
This feature is incompatible with Magic Castle. Therefore, it is turned off in
the instances metadata (`enable-oslogin="FALSE"`). The only account with sudoer rights
that can log in the cluster is configured by the variable `sudoer_username`
(default: `centos`).

### 10.1 Disable Puppet

If you plan to modify configuration files manually, you will need to disable
Puppet. Otherwise, you might find out that your modifications have disappeared
in a 30-minute window.

Puppet executes a run every 30 minutes and at reboot. To disable puppet:
```bash
sudo puppet agent --disable "<MESSAGE>"
```

### 10.2 Replace the Guest Account Password

Refer to section [4.11](#411-guest_passwd-optional).

### 10.3 Add LDAP Users

Users can be added to Magic Castle LDAP database (FreeIPA) with either one of
the following methods: hieradata, command-line, and Mokey web-portal. Each
method is presented in the following subsections.

New LDAP users are automatically assigned a home folder on NFS.

Magic Castle determines if an LDAP user should be member of a Slurm account
based on its POSIX groups. When a user is added to a POSIX group, a daemon
try to match the group name to the following regular expression:
```
(ctb|def|rpp|rrg)-[a-z0-9_-]*
```

If there is a match, the user will be added to a Slurm account with the same
name, and will gain access to the corresponding project folder under `/project`.

**Note**: The regular expression represents how Compute Canada names its resources
allocation. The regular expression can be redefined, see
[`profile::accounts:::project_regex`](https://github.com/ComputeCanada/puppet-magic_castle/#profileaccounts)

#### 10.3.1 hieradata

Using the [hieradata variable](#413-hieradata-optional) in the `main.tf`, it is possible to define LDAP users.

Examples of LDAP user definition with hieradata are provided in
[puppet-magic_castle documentation](https://github.com/computecanada/puppet-magic_castle#profileusersldapusers).

#### 10.3.2 Command-Line

To add a user account after the cluster is built, log in `mgmt1` and call:
```bash
kinit admin
IPA_GUEST_PASSWD=<new_user_passwd> /sbin/ipa_create_user.py <username> [--group <group_name>]
kdestroy
```

#### 10.3.3 Mokey

If user sign-up with Mokey is enabled, users can create their own account at
```
https://mokey.yourcluster.domain.tld/auth/signup
```

It is possible that an administrator is required to enable the account with Mokey. You can
access the administrative panel of FreeIPA at :
```
https://ipa.yourcluster.domain.tld/
```

The FreeIPA administrator credentials can be retrieved from an encrypted file
on the Puppet server. Refer to section [10.14](#1014-read-and-edit-secret-values-generated-at-boot)
to know how.

### 10.4 Increase the Number of Guest Accounts

To increase the number of guest accounts after creating the cluster with Terraform,
simply increase the value of `nb_users`, then call :
```
terraform apply
```

Each instance's Puppet agent will be reloaded following the copy of the hieradata files,
and the new accounts will be created.


### 10.5 Restrict SSH Access

By default, instances tagged `login` have their port 22 opened to entire world.
If you know the range of ip addresses that will connect to your cluster,
we strongly recommend that you limit the access to port 22 to this range.

To limit the access to port 22, refer to [section 4.14 firewall_rules](#414-firewall_rules-optional),
and replace the `cidr` of the `ssh` rule to match the range of ip addresses that
have be the allowed to connect to the cluster. If there are more than one range, create multiple rules
with distinct names.

### 10.6 Add Packages to Jupyter Default Python Kernel

The default Python kernel corresponds to the Python installed in `/opt/ipython-kernel`.
Each compute node has its own copy of the environment. To add packages to this
environment, add the following lines to `hieradata` in `main.tf`:
```yaml
jupyterhub::kernel::venv::packages:
  - package_A
  - package_B
  - package_C
```

and replace `package_*` by the packages you need to install.
Then call:
```
terraform apply
```

### 10.7 Activate Globus Endpoint

Refer to [Magic Castle Globus Endpoint documentation](globus.md).

### 10.8 Recovering from puppet rebuild

The modifications of some of the parameters in the `main.tf` file can trigger the
rebuild of the `puppet` instance. This instance hosts the Puppet Server on which
depends the Puppet agent of the other instances. When `puppet` is rebuilt, the other
Puppet agents cease to recognize Puppet Server identity since the Puppet Server
identity and certificates have been regenerated.

To fix the Puppet agents, you will need to apply the following commands on each
instance other than `puppet` once `puppet` is rebuilt:
```
sudo systemctl stop puppet
sudo rm -rf /etc/puppetlabs/puppet/ssl/
sudo systemctl start puppet
```

Then, on `puppet`, you will need to sign the new certificate requests made by the
instances. First, you can list the requests:
```
sudo /opt/puppetlabs/bin/puppetserver ca list
```

Then, if every instance is listed, you can sign all requests:
```
sudo /opt/puppetlabs/bin/puppetserver ca sign --all
```

If you prefer, you can sign individual request by specifying their name:
```
sudo /opt/puppetlabs/bin/puppetserver ca sign --certname NAME[,NAME]
```

### 10.9 Dealing with banned ip addresses (fail2ban)

Login nodes run [fail2ban](https://www.fail2ban.org/wiki/index.php/Main_Page), an intrusion
prevention software that protects login nodes from brute-force attacks. fail2ban is configured
to ban ip addresses that attempted to login 20 times and failed in a window of 60 minutes. The
ban time is 24 hours.


In the context of a workshop with SSH novices, the 20-attempt rule might be triggered,
resulting in participants banned and puzzled, which is a bad start for a workshop. There are
solutions to mitigate this problem.

#### 10.9.1 Define a list of ip addresses that can never be banned

fail2ban keeps a list of ip addresses that are allowed to fail to login without risking jail
time. To add an ip address to that list,  add the following lines
to the variable `hieradata` in `main.tf`:
```yaml
fail2ban::ignoreip:
  - x.x.x.x
  - y.y.y.y
```
where `x.x.x.x` and `y.y.y.y` are ip addresses you want to add to the ignore list.
The ip addresses can be written using CIDR notations.
The ignore ip list on Magic Castle already includes `127.0.0.1/8` and the cluster subnet CIDR.

Once the line is added, call:
```
terraform apply
```

#### 10.9.2 Remove fail2ban ssh-route jail

fail2ban rule that banned ip addresses that failed to connect
with SSH can be disabled. To do so, add the following line
to the variable `hieradata` in `main.tf`:
```yaml
fail2ban::jails: ['ssh-ban-root']
```
This will keep the jail that automatically ban any ip that tries to
login as root, and remove the ssh failed password jail.

Once the line is added, call:
```
terraform apply
```

#### 10.9.3 Unban ip addresses

fail2ban ban ip addresses by adding rules to iptables. To remove these rules, you need to
tell fail2ban to unban the ips.

To list the ip addresses that are banned, execute the following command:
```
sudo fail2ban-client status ssh-route
```

To unban ip addresses, enter the following command followed by the ip addresses you want to unban:
```
sudo fail2ban-client set ssh-route unbanip
```

#### 10.9.4 Disable fail2ban

While this is not recommended, fail2ban can be completely disabled. To do so, add the following line
to the variable `hieradata` in `main.tf`:
```yaml
fail2ban::service_ensure: 'stopped'
```

then call :
```
terraform apply
```

### 10.10 Generate a new SSL certificate

The SSL certificate configured by the dns module is valid for [90 days](https://letsencrypt.org/docs/faq/#what-is-the-lifetime-for-let-s-encrypt-certificates-for-how-long-are-they-valid).
If you plan to use your cluster for more than 90 days, you will need to generate a
new SSL certificate before the one installed on the cluster expires.

To generate a new certificate, use the following command on your computer:
```
terraform taint 'module.dns.module.acme.acme_certificate.certificate'
```

Then apply the modification:
```
terraform apply
```

The apply generates a new certificate, uploads it on the nodes that need it
and reloads the reverse proxy if it is configured.

### 10.11 Set SELinux in permissive mode

SELinux can be set in permissive mode to debug new workflows that would be
prevented by SELinux from working properly. To do so, add the following line
to the variable `hieradata` in `main.tf`:
```yaml
selinux::mode: 'permissive'
```

### 10.12 Create a compute node image

When scaling the compute node pool, either manually by changing the count or
automatically with [Slurm autoscale](./terraform_cloud.md#enable-magic-castle-autoscaling),
it can become beneficial to reduce the time spent configuring the machine
when it boots for the first time, hence reducing the time requires before it becomes
available in Slurm. One way to achieve this is to clone the root disk of a fully
configured compute node and use it as the base image of future compute nodes.

This process has three steps:

  1. Prepare the volume for image cloning
  2. Create the image
  3. Configure Magic Castle Terraform code to use the new image

The following subsection explains how to accomplish each step.

**Warning**: While it will work in most cases, avoid re-using the compute node image of a
previous deployment. The preparation steps cleans most
of the deployment specific configuration and secrets, but there is no guarantee
that the configuration will be entirely compatible with a different deployment.

#### 10.12.1 Prepare the volume for cloning

The environment [puppet-magic_castle](https://github.com/ComputeCanada/puppet-magic_castle/)
installs a script that prepares the volume for cloning named
[`prepare4image.sh`](https://github.com/ComputeCanada/puppet-magic_castle/blob/main/site/profile/files/base/prepare4image.sh).


To make sure a node is ready for cloning, open its puppet agent log and validate the
catalog was successfully applied at least once:
```bash
journalctl -u puppet | grep "Applied catalog"
```

To prepare the volume for cloning, execute the following line while connected to the compute node:
```bash 
sudo /usr/sbin/prepare4image.sh
```

Be aware that, since it is preferable for the instance to be powered off when cloning its volume, the
script halts the machine once it is completed. Therefore, after executing `prepare4image.sh`, you will
be disconnected from the instance.

The script `prepare4image.sh` executes the following steps in order:

  1. Stop and disable puppet agent
  2. Stop and disable slurm compute node daemon (`slurmd`)
  3. Stop and disable consul agent daemon
  4. Stop and disable consul-template daemon
  5. Unenroll the host from the IPA server
  6. Remove puppet agent configuration files in `/etc`
  7. Remove consul agent identification files
  8. Unmount NFS directories
  9. Remove NFS directories `/etc/fstab`
  10. Stop syslog
  11. Clear `/var/log/message` content
  12. Remove cloud-init's logs and artifacts so it can re-run
  13. Power off the machine

#### 10.12.2 Create the image

Once the instance is powered off, access your cloud provider dashboard, find the instance
and follow the provider's instructions to create the image.

- [AWS](https://docs.aws.amazon.com/toolkit-for-visual-studio/latest/user-guide/tkv-create-ami-from-instance.html)
- [Azure](https://learn.microsoft.com/en-us/azure/virtual-machines/capture-image-portal)
- [GCP](https://cloud.google.com/compute/docs/machine-images/create-machine-images#create-image-from-instance)
- [OpenStack](https://docs.openstack.org/horizon/latest/user/launch-instances.html#create-an-instance-snapshot)
- [OVH](https://blog.ovhcloud.com/create-and-use-openstack-snapshots/)

Note down the name/id of the image you created, it will be needed during the next step.

#### 10.12.3 Configure Magic Castle Terraform code to use the new image

Edit your `main.tf` and add `image = "name-or-id-of-your-image"` to the dictionary
defining the instance. The instance previously powered off will be powered on and future
non-instantiated machines will use the image at the next execution of `terraform apply`.

If the cluster is composed of heterogeneous compute nodes, it is possible
to create an image for each type of compute nodes. Here is an example with Google Cloud
```hcl
instances = {
  mgmt   = { type = "n2-standard-2", tags = ["puppet", "mgmt", "nfs"], count = 1 }
  login  = { type = "n2-standard-2", tags = ["login", "public", "proxy"], count = 1 }
  node   = {
    type = "n2-standard-2"
    tags = ["node", "pool"]
    count = 10
    image = "rocky-mc-cpu-node"
  }
  gpu    = {
    type = "n1-standard-2"
    tags = ["node", "pool"]
    count = 10
    gpu_type = "nvidia-tesla-t4"
    gpu_count = 1
    image = "rocky-mc-gpu-node"
  }
}
```

### 10.13 Generate and replace Puppet hieradata encryption keys

During the Puppet server initial boot, a pair of hiera-eyaml encryptions keys are generated in
`/opt/puppetlabs/puppet/eyaml`:
- `private_key.pkcs7.pem`
- `public_key.pkcs7.pem`

To encrypt the values before creating the cluster, the encryptions keys can be generated beforehand and then transferred on the Puppet server.

The keys can be generated with `eyaml`:
```
eyaml createkeys
```

or `openssl`:
```sh
openssl req -x509 -nodes -days 100000 -newkey rsa:2048 -keyout private_key.pkcs7.pem -out public_key.pkcs7.pem -subj '/'
```

The resulting public key can then be used to encrypt secrets, while the private and the public keys have to be transferred on the Puppet server to allow it to decrypt the values.

1. Transfer the keys on the Puppet server using SCP with SSH jumphost
    ```sh
    scp -J centos@cluster.yourdomain.cloud {public,private}_key.pkcs7.pem centos@puppet:~/
    ```
2. Replace the existing keys by the one transferred:
    ```sh
    ssh -J centos@cluster.yourdomain.cloud centos@puppet sudo cp {public,private}_key.pkcs7.pem /opt/puppetlabs/puppet/eyaml
    ```
3. Remove the keys from the admin account home folder:
    ```sh
    ssh -J centos@cluster.yourdomain.cloud centos@puppet rm {public,private}_key.pkcs7.pem
    ```

To backup the encryption keys from an existing Puppet server:

1. Create a readable copy of the encryption keys in the sudoer home account
    ```sh
    ssh -J centos@cluster.yourdomain.cloud centos@puppet 'sudo rsync --owner --group --chown=centos:centos /etc/puppetlabs/puppet/eyaml/{public,private}_key.pkcs7.pem ~/'
    ```
2. Transfer the files locally:
    ```sh
    scp -J centos@cluster.yourdomain.cloud centos@puppet:~/{public,private}_key.pkcs7.pem .
    ```
3. Remove the keys from the sudoer account home folder:
    ```sh
    ssh -J centos@cluster.yourdomain.cloud centos@puppet rm {public,private}_key.pkcs7.pem
    ```

### 10.14 Read and edit secret values generated at boot

During the cloud-init initialization phase,
[`bootstrap.sh`](https://github.com/ComputeCanada/puppet-magic_castle/blob/main/bootstrap.sh)
script is executed. This script generates a set of encrypted secret values that are required
by the Magic Castle Puppet environment:
- `profile::consul::acl_api_token`
- `profile::freeipa::mokey::password`
- `profile::freeipa::server::admin_password`
- `profile::freeipa::server::ds_password`
- `profile::slurm::accounting::password`
- `profile::slurm::base::munge_key`

To read or change the value of one of these keys, use `eyaml edit` command
on the `puppet` host, like this:
```
sudo /opt/puppetlabs/puppet/bin/eyaml edit \
  --pkcs7-private-key /etc/puppetlabs/puppet/eyaml/boot_private_key.pkcs7.pem \
  --pkcs7-public-key /etc/puppetlabs/puppet/eyaml/boot_public_key.pkcs7.pem \
  /etc/puppetlabs/code/environments/production/data/bootstrap.yaml
```

It also possible to redefine the values of these keys by adding the key-value pair to
the hieradata configuration file. Refer to section [4.13 hieradata](#413-hieradata-optional).
User defined values take precedence over boot generated values in the Magic Castle
Puppet data hierarchy.

### 10.15 Expand a volume

Volumes defined in the `volumes` map can be expanded at will. After their creation, you can
increase their size in the `main.tf` then call `terraform apply` and the associated block
device will be expanded.

To benefit from the new storage, the following commands need to be ran as root
on the instance to which the expanded volume is attached.
1. Identify the physical volume path
    ```
    pvscan
    ```
2. Expand the physical volume
    ``` 
    pvresize /dev/vdxyz # replace vdxyz by the volume identify at step 1
    ```
3. Identify the volume group path
    ``` 
    lvdisplay
    ```
4. Expand the volume group using step volume group path identified
    ```
    lvextend -l '+100%FREE' -r /dev/project_vg/project
    ```
5. Resize the XFS filesystem:
    ```
    xfs_growfs /dev/project_vg/project
    ```

## 11. Customize Magic Castle Terraform Files

You can modify the Terraform module files in the folder named after your cloud
provider (e.g: `gcp`, `openstack`, `aws`, etc.)

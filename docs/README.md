# Magic Castle Documentation

## Table of Content

1. [Setup](#1-setup)
2. [Cloud Cluster Architecture Overview](#2-cloud-cluster-architecture-overview)
3. [Initialization](#3-initialization)
4. [Configuration](#4-configuration)
5. [Cloud Specific Configuration](#5-cloud-specific-configuration)
6. [DNS Configuration and SSL Certificates](#6-dns-configuration-and-ssl-certificates)
7. [Planification](#7-planification)
8. [Deployment](#8-deployment)
9. [Destruction](#9-destruction)
10. [Online Cluster Configuration](#10-online-cluster-configuration)
11. [Customize Magic Castle Terraform Files](#11-customize-magic-castle-terraform-files)

## 1. Setup

To use Magic Castle you will need:
* Terraform (>= 0.12.21).
* Access to a Cloud (e.g.: Compute Canada Arbutus)
* Ability to communicate with the cloud provider API from your computer
* A cloud project with enough room for the resource described in section [1.1](#11-quotas).

### 1.1 Quotas

#### 1.1.1 OpenStack

* 1 floating IP
* 1 security group
* 3 volumes
* 3 instances
* 6 VCPUs
* 7 neutron port
* 8 GB of RAM
* 11 security rules
* 50 Volume Storage (GB)

#### 1.1.2 Google Cloud

**Global**
* 1 Network
* 1 Subnetwork
* 1 In-use IP address
* 1 Static IP address
* 1 Route
* 11 Firewall rules

**Region**
* 1 In-use IP addresses
* 8 CPUs
* 30 Local SSD (GB)
* 50 Persistent Disk Standard (GB)

To look and edit your GCP quota go to :
[https://console.cloud.google.com/iam-admin/quotas](https://console.cloud.google.com/iam-admin/quotas)

### 1.2 Authentication

#### 1.2.1 OpenStack / OVH

First, download your OpenStack Open RC file.
It is project-specific and contains the credentials used
by Terraform to communicate with OpenStack API. It comes
as a sourceable shell script. To download, using OpenStack webpage go to:
**Project** → **API Access**, then click on **Download OpenStack RC File**
then right-click on **OpenStack RC File (Identity API v3)**, **Save Link as...**, then
select the same folder that contains `main.tf`.

Second, in a terminal located in the same folder as your OpenStack RC file
and your `main.tf` file, source the OpenStack RC file.
```
$ source *-openrc.sh
```

This command will ask for a password, enter your OpenStack password.

#### 1.2.2 Google Cloud

1. Install the [Google Cloud SDK](https://cloud.google.com/sdk/docs/downloads-interactive)
2. In a terminal, enter : `gcloud auth application-default login`

### 1.3 Setup check

1. Open a terminal
2. Verify Terraform was properly installed by looking at the version
```
$ terraform version
```

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
$ terraform init
```

The initialization is specific to the folder where you are currently located.
The initialization process looks at all `.tf` files and fetches the plugins required
to build the resources defined in theses files. If you replace some or all
`.tf` files inside a folder that has already been initialized, just call the command
again to make sure you have all plugins.

The initialization process creates a `.terraform` folder at the root of your current
folder. You do not need to look at its content for now.

#### 3.2.1 Terraform Modules Upgrade

Once Terraform folder has been initialized, it is possible to fetch the new version
of the modules used by calling:
```
terraform init -upgrade
```

## 4. Configuration

The order of the input parameters we are about to present does not matter, but
we recommend leaving it as it is presented in the examples.

### 4.1 source

The first line of the module block indicates to Terraform where it can find
the `.tf` files that defines the resources that constitutes your future
cluster. We are pointing this variable at the cloud provider folder in the
release folder (i.e.: `./openstack`).

### 4.2 cluster_name

Defines the `ClusterName` variable in `slurm.conf` and the name of
the cluster in the Slurm accounting database
([see `slurm.conf` documentation](https://slurm.schedmd.com/slurm.conf.html)).

**Requirement**: Must be lowercase alphanumeric characters and start with a letter.

**Post Build Modification Effect**: rebuild of all instances at next `terraform apply`.

### 4.3 domain

Defines
* the Kerberos realm name when initializing FreeIPA.
* the internal domain name and the resolv.conf search domain as
`int.{cluster_name}.{domain}`

Optional modules following the current module in the example `main.tf` can
register the domain name if your domain's nameservers are administered
by one of the supported providers.
Refer to [section 6](#6-dns-configuration-and-ssl-certificates)
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

**Post Build Modification Effect**: rebuild of all instances at next `terraform apply`.

### 4.4 image

Defines the name of the image that will be used as the
base image for the cluster nodes. This image has to be based on CentOS 7.

You can use a custom CentOS 7 image if you wish, but provisioning customization
should be mainly done through Puppet scripting. Image customization is mostly
envisioned as a way to accelerate the provisioning process by applying the
security patches and OS updates in advance.

**Post Build Modification Effect**: None - if this variable is modified, existing
instances will ignore the change and future instances will use the new value.

#### 4.4.1 AWS

The image field needs to correspond to the Amazon Machine Image id or AMI.
The AMI is specific to each region, so make sure to use the right AMI for
the region you chose.

#### 4.4.2 Microsoft Azure

Azure requires multiple fields to define which image to choose. This field
is therefore not only a string, but a map that needs to contain the following
fields `publisher`, `offer` and `sku`.

#### 4.4.3 OVH

SELinux is not enabled in OVH provided CentOS 7 image. Since SELinux has to be
enabled for Magic Castle to work properly, you will need to build a custom image
of CentOS 7 with SELinux enabled.

To build such image, we recommend the usage of packer. OVH provides a document
explaining how to create a new image with packer:
[Create a custom OpenStack image with Packer](https://docs.ovh.com/gb/en/public-cloud/packer-openstack-builder/)

Before the end of the shell script ran to configure the image, add the
following line to activate SELinux:
```
sed -i s/^SELINUX=.*$/SELINUX=enforcing/ /etc/selinux/config
```

Once the image is built, make sure to use to input its name in your main.tf file.

### 4.5 nb_users

Defines how many user accounts will be created in
FreeIPA. Each user account shares the same randomly generated password.
The usernames are defined as `userX` where `X` is a number between 1 and
the value of `nb_users` (zero-padded, i.e.: `user01 if X < 100`, `user1 if X < 10`).

Each user has a home folder on a shared NFS storage hosted by the management
node.

User accounts do not have sudoer privileges. If you wish to use `sudo`,
you will have to login using the sudoer account and the SSH keys lists
in `public_keys`.

If you would like to add a user account after the cluster is built, refer to
section [10.3](#103-add-a-user-account) and [10.4](#104-increase-the-number-of-guest-accounts).

**Requirement**: Must be an integer, minimum value is 0.

**Post Build Modification Effect**: rebuild `mgmt1` instance at next `terraform apply`
([see section 10.8](#108-recovering-from-mgmt1-rebuild)).

### 4.6 instances

The `instances` variable is map with 3 keys: `mgmt`, `login` and `node`.

#### 4.6.1 mgmt

The value associated with the `mgmt` key is required to be a map
with 2 keys: `type` and `count`.

##### count

Number of management instances to create.

**Warning**: All other type of instances depend on the existence of at
least one management node named `mgmt1`. While it is possible to have
to 0 management vm and login or node count greater than 0, the cluster
will not be functional.

##### type

Cloud provider name for the combination of CPU, RAM and other features
on which will run the management instances.

Requirements:
- CPUs: 2 cores
- RAM: 6GB

#### 4.6.2 login

The value associated with the `login` key is required to be a map
with 2 keys: `type` and `count`.

##### count

Number of login instances to create.

##### type

Cloud provider name for the combination of CPU, RAM and other features
on which will run the login instances.

Requirements:
- CPUs: 2 cores
- RAM: 2GB

#### 4.6.3 node

The value associated with the `login` key is required to be a list of
map with at least two keys: `type` and `count`.

If the list contains more than one map, at least one of the map will need
to define a value for the key `prefix`.

##### count

Number of compute node instances to create.

##### type

Cloud provider name for the combination of CPU, RAM and other features
on which will run the compute node instances.

Requirements:
- CPUs: 1 core
- RAM: 2GB

##### prefix (optional)

Each compute node is identified by a unique hostname. The default hostname
structure is `node` followed by the node 1-based index, i.e: `node1`. When
more than one map is provided in the `instances["node"]` list, a prefix has
to be defined for at least one of the map to avoid hostname conflicts.

When a prefix is configured, the hostname structure is `prefix-node` followed
by the node index in its map. For example, the following `instance["node"]`
list
```
[
  { type = "p2-4gb",     count = 4 },
  { type = "c2-15gb-31", count = 2, prefix = "highmem" },
  { type = "gpu2.large", count = 3, prefix = "gpu" },
]
```
would spawn compute nodes with the following hostnames:
```
node1
node2
node3
node4
highmem-node1
highmem-node2
gpu-node1
gpu-node2
gpu-node3
```

#### 4.6.4 Post Build Modification Effect

count and type variables can be modified at any point of your cluster lifetime.
Terraform will manage the creation or destruction of the virtual machines
for you.

Modifying any of these variables after the cluster is built will only affects
the type of instances associated with the variables at next `terraform apply`.

### 4.7 Storage: type, home_size, project_size, scratch_size

Define the type of network storage and the size of the volumes
for respectively `/home`, `/project` and `/scratch`.

If `type` is set to `nfs`, each volume is mounted on `mgmt1` and
exported with NFS to the login and the compute nodes.

**Post Build Modification Effect**: destruction of the corresponding volumes and attachments, and creation
of new empty volumes and attachments.

### 4.8 public_keys

List of SSH public keys that will have access to your cluster sudoer account.

**Note 1**: You will need to add the private key associated with one of the public
keys to your local authentication agent (i.e: `ssh-add`) if you use the
DNS module. The DNS module uses the SSH key to copy files to the login node
after the cluster instances are created.

**Note 2**: The SSH key type has to be ECDSA or RSA for some cloud providers
including AWS and OpenStack because they do not support ed25519 and DSA
is deprecated.

**Post Build Modification Effect**: rebuild of all instances at next `terraform apply`.

### 4.9 guest_passwd (optional)

**default value**: 4 random words separated by a dot

Defines the password for the guest user accounts instead of using a
randomly generated one.

**Requirement**: Minimum length **8 characters**.

**Post Build Modification Effect**: rebuild `mgmt1` instance at next `terraform apply`
([see section 9.8](#98-recovering-from-mgmt1-rebuild)).

### 4.10 root_disk_size (optional)

**default value**: 10

Defines the size in gibibyte (GiB) of each instance's root volume that contains
the operating system and softwares required to operate the cluster services.

**Post Build Modification Effect**: rebuild of all instances at next `terraform apply`.

### 4.11 sudoer_username (optional)

**default value**: `centos`

Defines the username of the account with sudo privileges. The account
ssh authorized keys are configured with the SSH public keys with
`public_keys`.

**Post Build Modification Effect**: rebuild of all instances at next `terraform apply`.

### 4.12 hieradata (optional)

**default value**: empty string

Defines custom Puppet variable values that are injected in the hieradata file.
Useful to override common configuration of Puppet classes.

**Requirement**: The string needs to respect a YAML syntax.

**Post Build Modification Effect**: rebuild `mgmt1` instance at next `terraform apply`
([see section 9.8](#98-recovering-from-mgmt1-rebuild)).

## 5. Cloud Specific Configuration

### 5.1 OpenStack and OVH

#### 5.1.1 os_floating_ips (optional)

**default value**: None

Defines a list of pre-allocated floating ip addresses
that will be assigned to the login nodes. If this variable is left empty,
(e.g. : `[]`) the login nodes' floating ips will be managed by Terraform.

This variable can be useful if you administer your DNS manually and
you would like the keep the same domain name for your cluster at each
build.

**Post Build Modification Effect**: change the floating ips assigned to the login nodes.

#### 5.1.2 os_ext_network (optional)

**default value**: None

Defines the name of the external network that provides the floating
IPs. Define this only if your OpenStack cloud provides multiple
external networks, otherwise, Terraform can find it automatically.

**Post Build Modification Effect**: change the floating ips assigned to the login nodes.

#### 5.1.3 os_int_network (optional)

**default value**: None

Defines the name of the internal network that provides the subnet
on which the instances are connected. Define this only if you
have more than one network defined in your OpenStack project.
Otherwise, Terraform can find it automatically.

**Post Build Modification Effect**: rebuild of all instances at next `terraform apply`.

#### 5.1.4 os_int_subnet (optional)

**default value**: None

Defines the name of the internal subnet on which the instances are
connected. Define this only if you have more than one subnet defined in your
OpenStack network. Otherwise, Terraform can find it automatically.
Can be used to force a v4 subnet when both v4 and v6 exist.

**Post Build Modification Effect**: rebuild of all instances at next `terraform apply`.

### 5.2 Google Cloud

#### 5.2.1 project_name

#### 5.2.2 region

#### 5.2.3 zone (optional)

#### 5.2.4 gpu_per_node

### 5.3 Amazon Web Services

#### 5.3.1 region

#### 5.3.2 availability_zone (optional)

### 5.4 Microsoft Azure

#### 5.4.1 location

#### 5.4.2 managed_disk_type (optional)

#### 5.4.3 azure_resource_group (optional)

**default value**: None

Defines the name of an already created resource group to use. Terraform
will no longer attempt to manage a resource group for Magic Castle if
this variable is defined and will instead create all resources within
the provided resource group. Define this if you wish to use an already
created resource group or you do not have subscription level access to
create and destroy resource groups.

**Post Build Modification Effect**: rebuild of all instances at next `terraform apply`.


## 6. DNS Configuration and SSL Certificates

Some functionalities in Magic Castle require the registration of DNS records under the
[cluster name](#42-cluster_name) in the selected [domain](#43-domain). This includes
web services like JupyterHub, Globus and FreeIPA web portal.

If your domain DNS records are managed by one of the supported providers,
follow the instructions in the corresponding sections to have the DNS records and SSL
certificates managed by Magic Castle.

If you DNS providers is not supported, you can manually create the DNS records and
generate the SSL certificates. Refer to the last subsection for more details.

**Requirement**: A private key associated with one of the
[public keys](#48-public_keys) needs to be tracked (i.e: `ssh-add`) by the local
[authentication agent](https://www.ssh.com/ssh/agent) (i.e: `ssh-agent`).
This module uses the ssh-agent tracked SSH keys to authenticate and
to copy SSL certificate files to the login nodes after their creation.

### 6.1 CloudFlare

1. Uncomment the `dns` module for CloudFlare in your `main.tf`.
2. Uncomment the `output "dns"` block.
3. In the `dns` module, configure the variable `email` with your email address. This will be used to generate the Let's Encrypt certificate.
4. Download and install the CloudFlare Terraform module: `terraform init`.
5. Export the environment variables `CLOUDFLARE_EMAIL` and `CLOUDFLARE_API_KEY`, where `CLOUDFLARE_EMAIL` is your Cloudflare account email adress and `CLOUDFLARE_API_KEY` is your account Global API Key available in your [CloudFlare profile](https://dash.cloudflare.com/profile/api-tokens).

#### 6.1.2 CloudFlare API Token

If you prefer using an API token instead of the global API key, you will need to configure a token with the following four permissions with the [CloudFlare API Token interface](https://dash.cloudflare.com/profile/api-tokens).

| Section | Subsection | Permission|
| ------------- |-------------:| -----:|
| Account | Account Settings | Read|
| Zone | Zone Settings | Read|
| Zone | Zone | Read|
| Zone | DNS | Write|

Instead of step 5, export only `CLOUDFLARE_API_TOKEN`, `CLOUDFLARE_ZONE_API_TOKEN`, and `CLOUDFLARE_DNS_API_TOKEN` equal to the API token generated previously.

### 6.2 Google Cloud

**requirement**: Install the [Google Cloud SDK](https://cloud.google.com/sdk/docs/downloads-interactive)

1. Login to your Google account with gcloud CLI : `gcloud auth application-default login`
2. Uncomment the `dns` module for Google Cloud in your `main.tf`.
3. Uncomment the `output "hostnames"` block.
4. In `main.tf`'s `dns` module, configure the variable `email` with your email address. This will be used to generate the Let's Encrypt certificate.
5. In `main.tf`'s `dns` module, configure the variables `project_name` and `zone_name`
with their respective values as defined by your Google Cloud project.
6. Download and install the Google Cloud Terraform module: `terraform init`.

### 6.3 Unsupported providers

If your DNS provider is not currently supported by Magic Castle, you can create the DNS records
and the SSL certificates manually.

#### 6.3.1 DNS Records

The DNS records registerd by Magic Castle are listed in
[dns/record_generator/main.tf](https://github.com/ComputeCanada/magic_castle/blob/master/dns/record_generator/main.tf). All records point to the one of login nodes.

These are the records that need to be created in your DNS provider.

#### 6.3.2 SSL Certificates

Magic Castle generates with Let's Encrypt a wildcard certificate for `*.cluster_name.domain`.
You can use [certbot](https://certbot.eff.org/docs/using.html#dns-plugins) DNS challenge
plugin to generate the wildcard certificate.

You will then need to copy the certificate files in the proper location on each login node.
Apache configuration expects the following files to exist:
- `/etc/letsencrypt/live/${domain_name}/fullchain.pem`
- `/etc/letsencrypt/live/${domain_name}/privkey.pem`
- `/etc/letsencrypt/live/${domain_name}/chain.pem`

Refer to the [reverse proxy configuration](https://github.com/ComputeCanada/puppet-magic_castle/blob/master/site/profile/manifests/reverse_proxy.pp) for more details.

## 7. Planification

Once your initial cluster configuration is done, you can initiate
a planning phase where you will ask Terraform to communicate with
your cloud provider and verify that your cluster can be built as it is
described by the `main.tf` configuration file.

Terraform should now be able to communicate with your cloud provider.
To test your configuration file, enter the following command
```
$ terraform plan
```

This command will validate the syntax of your configuration file and
communicate with the provider, but it will not create new resources. It
is only a dry-run. If Terraform does not report any error, you can move
to the next step. Otherwise, read the errors and fix your configuration
file accordingly.

## 8. Deployment

To create the resources defined by your main, enter the following command
```
$ terraform apply
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
first phase of the cluster-building process. The provisioning: the
creation of the user accounts, installation of FreeIPA, Slurm, configuration
of JupyterHub, etc.; takes around 15 minutes after the instances are created.

You can follow the provisioning process on the issuance by looking at:

* `/var/log/cloud-init-output.log`
* `sudo journalctl -u puppet`

once the instances are booted.

If unexpected problems occur during provisioning, you can provide these
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
$ terraform apply
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
$ terraform destroy -refresh=false
```

The `-refresh=false` flag is to avoid an issue where one or many of the data
sources return no results and stall the cluster destruction with a message like
the following:
```
Error: Your query returned no results. Please change your search criteria and try again.
```
This type of error happens when for example the specified [image](#44-image)
no longer exists (see [issue #40](https://github.com/ComputeCanada/magic_castle/issues/40)).

As for `apply`, Terraform will output a plan that you will have to confirm
by entering `yes`.

**Warning**: once the cluster is destroyed, nothing will be left, even the
shared storage will be erased.

### 9.1 Instance Destruction

It is possible to destroy only the instances and keep the rest of the infrastructure
like the floating ip, the volumes, the generated SSH hostkey, etc. To do so, set
the count value of the instance type you wish to destroy to 0.

### 9.2 Reset

On some occasions, it is desirable to rebuild some of the instances from scratch.
Using `terraform taint`, you can designate ressources that will be rebuild at
next application of the plan.

To rebuild the first login node :
```
terraform taint 'module.openstack.openstack_compute_instance_v2.login[0]'
terraform apply
```

## 10. Online Cluster Configuration

Once the cluster is online and provisioned, you are free to modify
its software configuration as you please by connecting to it and
abusing your administrator privileges. If after modifying the
configuration, you think it would be good for Magic Castle to
support your new features, make sure to submit an issue on the
git repo or fork the puppet-magic_castle repo and make a pull request.

We will list here a few common customizations that are not currently
supported directly by Magic Castle, but that are easy to do live.

Most customizations are done from the management node (`mgmt1`).
To connect to the management node, follow these steps:

1. Make sure your SSH key is loaded in your ssh-agent.
2. SSH in your cluster with forwarding of the authentication
agent connection enabled: `ssh -A centos@cluster_ip`.
Replace `centos` by the value of `sudoer_username` if it is
different.
3. SSH in the management node : `ssh mgmt1`

**note on Google Cloud**: In GCP, [OS Login](https://cloud.google.com/compute/docs/instances/managing-instance-access)
lets you use Compute Engine IAM roles to manage SSH access to Linux instances.
This feature is incompatible with Magic Castle. Therefore, it is turned off in
the instances metadata (`os_login="FALSE`). The only account with admin rights
that can log in the cluster is configured by the variable `sudoer_username`
(default: `centos`).

### 10.1 Disable Puppet

If you plan to modify configuration files manually, you will need to disable
Puppet. Otherwise, you might find out that your modifications have disappeared
in a 30-minute window.

puppet is executed every 30 minutes and at every reboot through the puppet agent
service. To disable puppet:
```bash
sudo puppet agent --disable "<MESSAGE>"
```

### 10.2 Replace the User Account Password

A four words password might not be ideal for workshops with new users
who barely know how to type. To replace the randomly generated
password of the user accounts, follow these steps:

1. Connect to the cluster.
2. Create a variable containing the randomly generated password: `OLD_PASSWD=<random_passwd>`
3. Create a variable containing the new human defined password: `NEW_PASSWD=<human_passwd>`.
This password must respect the FreeIPA password policy. To display the policy enter
```
# Enter FreeIPA admin password available in /etc/puppetlabs/code/environments/production/data/terraform_data.yaml
$ kinit admin
$ ipa pwpolicy-show
$ kdestroy
```
4. Loop on all user accounts to replace the old password by the new one:
```
for username in $(ls /home/ | grep user); do
  echo -e "$OLD_PASSWD" | kinit $username
  echo -e "$NEW_PASSWD\n$NEW_PASSWD" | ipa user-mod $username --password
  kdestroy
done
```

### 10.3 Add a User Account

To add a user account after the cluster is built, log in `mgmt1` and call:
```bash
$ kinit admin
$ IPA_ADMIN_PASSWD=<freeipa_passwd> IPA_GUEST_PASSWD=<new_user_passwd> /sbin/ipa_create_user.py <username>
$ kdestroy
```

To allow the user to submit jobs, create a Slurm account for the user:
```
$ sudo /opt/software/slurm/bin/sacctmgr add account <username_account> -i
```

then add the user to Slurm database
```bash
$ sudo /opt/software/slurm/bin/sacctmgr add user <username> Account=<username_account> -i
```

### 10.4 Increase the Number of Guest Accounts

The number of guest accounts is originally set in the Terraform main file. If you wish
to increase the number of guest accounts after creating the cluster with Terraform, you
can modify the hieradata file of the Puppet environment.

1. On `mgmt1` and with `sudo`, open the file
```
/etc/puppetlabs/code/environments/production/data/terraform_data.yaml
```
2. Increase the number associated with the field `profile::freeipa::guest_accounts::nb_accounts:`
to the number of guest accounts you want.
3. Save the file.
4. Restart puppet on `mgmt1`: `sudo systemctl restart puppet`.
5. The accounts will be created in the following minutes.


### 10.5 Restrict SSH Access

By default, port 22 of the login node is accessible from the world.
If you know the range of ip addresses that will connect to your cluster,
we strongly recommend you to limit the access to port 22 to this range.

#### 10.5.1 OpenStack

You can use OpenStack webpage.

1. In OpenStack webpage, go to: **Project** → **Network** → **Security Groups**
2. In the Security Groups table, there should be a line named like your cluster
with the suffix `_secgroup`. Click on the corresponding **Managed Rules** button.
3. Find the line with **22 (SSH)** in the **Port Range** column and
click on the **Delete Rule** button.
Click **Delete Rule** in the following message box.
4. Click on the **Add Rule** button.
5. Select **SSH** in Rule dropping list
6. Define the range of ip addresses in the CIDR box.
7. Click on Add
8. Repeat 3 to 6 if you have multiple ip ranges.

Try to SSH in your cluster. If the connection times out, your ip address is out
of the range of you entered or you made a mistake when defining the range.
Repeat from step 3.

### 10.6 Add Packages to Jupyter Default Python Kernel

The default Python kernel corresponds to the Python installed in `/opt/ipython-kernel`.
Each compute node has its own copy of the environment. To install packages in
this environment, on a compute node call:

```
sudo /opt/ipython-kernel/bin/pip install <package_name>
```

This will install the package on a single compute node. To install it on every
compute node, call the following command from the sudoer account and where `N`
is the number of compute nodes in your cluster.

```
pdsh -w node[1-N] sudo /opt/ipython-kernel/bin/pip install <package_name>
```

### 10.7 Activate Globus Endpoint

Refer to [Magic Castle Globus Endpoint documentation](globus.md).

### 10.8 Recovering from mgmt1 rebuild

The modifications of some of the parameters in the `main.tf` file can trigger the
rebuild of the `mgmt1` instance. This instance hosts the Puppet Server on which
depends the Puppet agent of the other instances. When `mgmt1` is rebuild, the other
Puppet agents cease to recognize Puppet Server identity since the Puppet Server
identity and certificates have been regenerated.

To fix the Puppet agents, you will need to apply the following commands on each
instance other than `mgmt1` once `mgmt1` is rebuilt:
```
sudo systemctl stop puppet
sudo rm -rf /etc/puppetlabs/puppet/ssl/
sudo systemctl start puppet
```

Then, on `mgmt1`, you will need to sign the new certificate requests made by the
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

## 11. Customize Magic Castle Terraform Files

You can modify the Terraform module files in the folder named after your cloud
provider (e.g: `gcp`, `openstack`, `aws`, etc.)

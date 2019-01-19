# Magic Castle Workshop
Version: 1.0

## Summary

## Overview of Real-World Examples

## Workshop Cases

## Setup
For the workshop you will need

* Terraform (latest or 0.11.11).
* git
* A Compute Canada Cloud account

The project can be used to build clusters with commercial cloud, but it implies cost or access to credit.

## Overview of the Cloud Cluster Architecture

**TODO: Insert image of the cluster and the repartition of the services**
https://draw.io/

## Building Your First Cloud Cluster

### Setup check

1. Open a terminal
2. Verify the commands were properly installed by looking at the version

    * `git version`
    * `terraform version`

3. Verify you have added your SSH key inside GitLab. Go to https://git.computecanada.ca/profile/keys

### Copying a Child Module

1. Go to https://git.computecanada.ca/fafor10/slurm_cloud.
2. Star the repo ;).
3. Click on the `examples` folder.
4. Click on the `openstack` folder.
6. Click on the `arbutus` folder. For those who do not have an account on Arbutus, select the cloud corresponding to your account.
7. Click on `main.tf`

This file contains Terraform modules and outputs. Modules are files that defines a set of
ressources that will be configured based on the inputs provided in the module block.
Outputs are used to tell Terraform which variables of
our module we would like to be shown on screen once the ressources have been instantiated.

1. Open a Terminal.
2. Create a new folder. Name it after your favorite superhero: `mkdir hulk`
3. Move inside the folder: `cd hulk`
4. Save a copy of the preceding `main.tf` file inside your new folder.
```
wget https://git.computecanada.ca/\
     fafor10/slurm_cloud/raw/examples/\
     openstack/arbutus/main.tf
```

This file will be our main canvas to design our new clusters. As long as the module block
parameters suffice to our need, we will be able to limit our configuration to this sole
file. Further customization will be addressed during the second part of the workshop.

### Initializing Terraform Process

Terraform fetches the plugins required to interact with the cloud provider defined by
our `main.tf` once when we initialize. To initialize, enter the following command:
```
$ terraform init
```

The initialization is specific to the folder where you are currently located.
The initialization process looks at all `.tf` files and fetches the plugins required
to build the ressources defined in theses files. If your replace some or all
`.tf` files inside a folder that has already been initialized, just call the command
again to make sure you have all plugins.

The initialization process creates a `.terraform` folder at the root of your current
folder. You do not need to look at its content for now.

### Customizing Your Cluster

The order of the input parameters we are about to present does not matter, but
we recommend leaving it as it is presented in the examples.

#### source

The first line of the module block indicates to Terraform where it can find
the `.tf` files that defines the resources that constitutes your future
cluster. We are pointing this variable toward the git repo using the syntax
defined in [Terraform documentation](https://www.terraform.io/docs/modules/sources.html#generic-git-repository)

The git repository of the project subfolders are divided by cloud provider.
If you were to fork this project, you would need to replace the
source value by the link to your own fork.

Beware, not all cloud provider module uses the same variables.
You should refer to the examples specific to the cloud provider
you want to use.

#### `cluster_name`

`cluster_name` is used to:

* Define the `ClusterName` variable in `slurm.conf`.  This is the name by
which this Slurm managed cluster is known in the accounting database
([see `slurm.conf` documentation](https://slurm.schedmd.com/slurm.conf.html)).
* Define the hostname of the login node.

Define with lowercase alphanumeric characters and start with a letter.

Modifying this variable after the cluster is built leads to a complete
cluster rebuild at next `terraform apply`.

#### `domain`

`domain` defines:

* the Kerberos realm name when initializing FreeIPA.
* the internal domain name and the resolv.conf search domain as
`int.{cluster_name}.{domain}`

If you own a domain, you can register the login floating IP address
under `{cluster_name}.{domain}` manually with your registrar. An optional
module following the `openstack` module in the example `main.tf` can
register the domain name if your domain's nameservers are administred
by CloudFlare.

Modifying this variable after the cluster is built leads to a complete
cluster rebuild at next `terraform apply`.

#### `nb_nodes`

`nb_nodes` defines how many compute node instances
will be created. This integer can be between 0 and your cloud allocation
instance upper limit minus 2 (you must leave room for a management and
a login node).

This variable can be modified at any point of your cluster lifetime.
Terraform will manage the creation or destruction of the virtual machines
for you. It is therefore possible to start with 0 compute nodes, build the
cluster, and add more later.

Modifying this variable after the cluster is built only affects the number
of compute nodes at next `terraform apply`.

#### `nb_users`

`nb_users` defines how many user accounts will be created in
FreeIPA. Each user account shares the same randomly generated password.
The usernames are defined as `userX` where `X` is a number between 1 and
the value of `nb_users` (zero-padded, i.e.: `user01 if X < 100`, `user1 if X < 10`).

Each user has a home folder on a shared NFS storage hosted by the management
node.

User accounts do not have administrator privileges. If you wish to use `sudo`,
you will have to login using the administrator account named `centos` and the
SSH key defined by `public_key_path`.

If you would like to add a user account after the cluster is built. Log in the
management node and call:
```
$ IPA_ADMIN_PASSWD=<admin_passwd> IPA_GUEST_PASSWD=<new_user_passwd> \
 /sbin/ipa_create_user.sh <username>
```

Modifying `nb_users` after the cluster is built leads to a complete
cluster rebuild at next `terraform apply`.

#### `shared_storage_size`

`shared_storage_size` defines the size of the management node single volume.
This volume hosts four NFS exports that are mounted on the login node and the
compute nodes:

1. `/home`
2. `/project`
3. `/scratch`
4. `/etc/slurm`

Modifying this variable after the cluster is built lead to a complete
cluster rebuild at next `terraform apply`.

#### `public_key_path`

`public_key_path` is a path to an SSH public key file of your choice.
This key will associated with the `centos` account to provide you
administrative access to the cluster.

Modifying this variable after the cluster is built leads to a complete
cluster rebuild at next `terraform apply`.

#### `globus_user` and `globus_password` (**optional**)

`globus_user` and `globus_password` are optional credentials that, when provided,
are used to register a Globus Endpoint on [globus.org](globus.org). This endpoint will point
to the NFS storage and could be used to demonstrate users how to use Globus or
transfer file to and from the cloud cluster.

The name of the registered endpoint corresponds to `{cluster_name}.{domain}`.

Modifying these variables after the cluster is built leads to a complete
cluster rebuild at next `terraform apply`.

#### `os_external_network`

`os_external_network` defines the name of the OpenStack external network.
It is used to allocate a floating-ip that will be associated with the
login node. Each Compute Canada Cloud OpenStack has its own external
network and they are all named differently. For future references:

* Arbutus: `Public-Network`
* East Cloud: `net04_ext` 
* West Cloud: `VLAN3337`

If you are using a different OpenStack instance, to find the name of
your external network, in the OpenStack web UI go to : Project → Network → Networks,
and then look for the name of the network which **External** column is set
to **Yes**.

Modifying this variable after the cluster is built leads to a rebuild of the
login node and a renew of its floating ip at next `terraform apply`.

#### `os_image_name`

`os_image_name` defines the name of the image that will be used as the
base image for the cluster nodes. For the provisionning to work properly,
this image has to be a CentOS 7 based image.

You can use custom CentOS 7 image if you wish, but provisioning custommization
should be mainly done through Puppet scripting. Image customization is mostly
envision to accelerate the provisioning process by applying in advance the
security patches and general OS updates.

Modifying this variable after the cluster is built lead to a complete
cluster rebuild at next `terraform apply`.

#### `os_flavor_mgmt`, `os_flavor_login` and `os_flavor_node`.

`os_flavor_*` defines the flavor of one of the three types of servers
in the cluster: mgmt, login and node (compute node). A flavor in OpenStack
defines the compute, memory, and storage capacity of an instance.

For `os_flavor_mgmt`, choose a flavor with at least 3GB of memory.

Modifying one of these variables after the cluster is built lead
to a rebuild of the instances with the corresponding type.

#### `os_floating_ip` (**optional**)

**TODO: Document this variable**

### Planning Cluster Deployment

Once your initial cluster configuration is done, you can initiate
a planning phase where you will ask Terraform to communicate with
OpenStack and verify that your cluster can be built as it is
described by the `main.tf` configuration file.

First, you will have to download your OpenStack Open RC
file. It is project-specific and contains the credentials used
by Terraform to communicate with OpenStack API. It comes
as a sourcable shell-script. To download, using OpenStack web
ui go to : **Project** → **API Access**, then click on **Download OpenStack RC File**
then right-click on **OpenStack RC File (Identity API v3)**, **Save Link as...**, then
select the same folder that contains `main.tf`.

Second, in a terminal located in the same folder as your OpenStack RC file
and your `main.tf` file, source the OpenStack RC file.

```$ source *-openrc.sh```

This command will ask for a password, enter your Compute Canada password.

Terraform should now be able to communicate with OpenStack. To test your
configuration file, enter the following command

```$ terraform plan```

This command will validate the syntax of your configuration file and
communicate with OpenStack, but it will not create new resources. It
is only a dry-run. If Terraform does not report any error, you can move
to the next step. Otherwise, read the errors and fix your configuration
file accordingly.

### Applying the Configuration File


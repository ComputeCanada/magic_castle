# Magic Castle Workshop
Version: 1.0

## Summary

## Overview of Real-World Examples

## Workshop Cases

## Setup
For the workshop you will need

* the latest release of Terraform (0.11.10).
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
3. Instead of `master`, select the branch named `puppet`.
4. Click on the `examples` folder.
5. Click on the `openstack` folder.
6. Verify everyone has an arbutus cloud account.
7. Click on the `arbutus` folder. For those who do not have an account on Arbutus, select the cloud corresponding to your account.
8. Click on `main.tf`

This file contains a Terraform module. A module block instructs Terraform to create an
instance of a module, and in turn to instantiate any resources defined within it. The
first block of the file configure the module source and its parameters.

The other blocks in the file are output. They are used to tell Terraform which variables of
our module we would like to be shown on screen once the ressources have been instantiated.

1. Open a Terminal.
2. Create a new folder. Name it after your favorite superhero: `mkdir hulk`
3. Move inside the folder: `cd hulk`
4. Save a copy of the preceding `main.tf` file inside your new folder.
```
wget https://git.computecanada.ca/\
     fafor10/slurm_cloud/raw/puppet/\
     examples/openstack/arbutus/main.tf
```

This file will be our main canvas to design our new clusters. As long as the module block
parameters suffice to our need, we will be able to limit our configuration to this sole
file. Further customization will be addressed during the second part of the workshop.

### Initializing Terraform Process

Terraform fetches the plugins required to interact with the cloud provider defined by
our `main.tf` once when we initialize. To initialize, enter the following command:
```
terraform init
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

Modifying this variable after the cluster is built lead to a complete
cluster rebuild at next `terraform apply`.

#### `nb_nodes`

`nb_nodes` defines how many compute nodes virtual machines
will be created. This integer can be between 0 and your cloud allocation
instance upper limit minus 2 (you must leave space for a management and
a login node).

This variable can be modified at any point of your cluster lifetime.
Terraform will manage the creation or destruction of the virtual machines
for you. It is therefore possible to start with 0 compute nodes, build the
cluster, and later add more.

Modifying this variable after the cluster is built only affect the number
of compute nodes at next `terraform apply`.

#### `nb_users`

`nb_users` defines how many user accounts will be created in
FreeIPA. Each user account shares the same randomly generated password.
The usernames are defined as `userX` where `X` is a number between 1 and
the value of `nb_users`.

Each user has a home folder on a shared NFS storage hosted by the management
node.

User accounts do not have administrator privileges. If you wish to use `sudo`,
you will have to login using the administrator account named `centos` and the
SSH key defined by `public_key_path`.

Modifying this variable after the cluster is built lead to a complete
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

#### `domain_name`

`domain_name` is used to:

* Define the Kerberos realm name when initializing FreeIPA.
* Define the internal domain name and the resolv.conf search domain as
`int.{domain_name}`
* If the domain is registered with CloudFlare and you have administrative
rights, it will be used to register a new entry in the DNS (**optional**).

If you own a domain but it is not administred with CloudFlare, you can
registered the IP address under this domain name manually with your
registrar once the cluster is built.

Modifying this variable after the cluster is built lead to a complete
cluster rebuild at next `terraform apply`.

#### `public_key_path`

`public_key_path` is the path to the file that contains an SSH public
key. This key will associated with the `centos` account to provide you
administrative access to the cluster.

Modifying this variable after the cluster is built lead to a complete
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

Modifying this variable after the cluster is built lead to a rebuild of the
login node and a renew of its floating ip at next `terraform apply`.

#### `os_image_name`


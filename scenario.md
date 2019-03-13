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
5. Click on `main.tf`

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

### Configuring Your Cluster

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

Modifying `nb_users` after the cluster is built leads to a rebuild 
of the management node at next `terraform apply`.

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

#### `os_image_name`

`os_image_name` defines the name of the image that will be used as the
base image for the cluster nodes. For the provisionning to work properly,
this image has to be based on CentOS 7.

You can use custom CentOS 7 image if you wish, but provisioning custommization
should be mainly done through Puppet scripting. Image customization is mostly
envision to accelerate the provisioning process by applying in advance the
security patches and general OS updates.

Modifying this variable after the cluster is built leads to a complete
cluster rebuild at next `terraform apply`.

#### `os_flavor_mgmt`, `os_flavor_login` and `os_flavor_node`.

`os_flavor_*` defines the flavor of one of the three types of servers
in the cluster: mgmt, login and node (compute node). A flavor in OpenStack
defines the compute, memory, and storage capacity of an instance.

For `os_flavor_mgmt`, choose a flavor with at least 3GB of memory.

Modifying one of these variables after the cluster is built leads
to a live migration of the instance(s) to the new chosen flavor. The
affected instances will reboot in the process.

#### `os_floating_ip` (**optional**)

`os_floating_ip` defines pre-allocated floating ip address that will
be assign to the login node. If this variable is left empty, the
floating ip will be managed by Terraform.

This variable can be useful if you administered your DNS manually and
you would like the keep the same domain name for your cluster at each
build.

Modifying this variable after the cluster is built will change the
floating ip assigned to the login node.

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

### Creating the Cluster

To create the resources defined by your module, enter the following command
```
$ terraform apply
```

The command will produce the same output as the `plan` command, but after
the output it will ask for a confirmation to perform the proposed actions.
Enter `yes`.

Terraform will then proceed to create the resources defined by the
configuration file. It should take a few minutes. Once the creation process
is completed, Terraform will output the administror password, the user
account password, the administrator username and the floating ip of the login
node.

**Beware**, altough the instance creation process is finished once Terraform
outputs the connection information, you will not be able to
connect and use the cluster immediately. The instance creation is only the
first phase of the cluster building process. The provisioning: the
creation of the user accounts, installation of FreeIPA, Slurm, configuration
of JupyterHub, etc.; takes around 15 minutes after the instances are created.

You can follow the provisioning process on the insances by looking at:

* `/var/log/cloud-init-output.log`
* `/var/log/puppetlabs/puppet/puppet.log` (require admin privileges)

once the instances are booted.

If unexpected problems occur during provisioning, you can provide these
logs to the authors of Magic Castle to help you debug.

### Modifying the Cluster Infrastructure

You can modify the `main.tf` at any point of your cluster's life and
apply the modifications while it is running. Depending on the variables
you modify, Terraform will destroy some or all resources for recreate
them. We have previously identify the effect of modifying each variable
in their own section of this document.

For example, to increase the number of computes nodes by one. Open
`main.tf`, add 1 to `nb_nodes`, save the document and call
```
$ terraform apply
```

Terraform will analyze the difference between the current state and
the future state, and plan the creation of a single new instance. If
you accept the action plan, the instance will be created, provisioned
and eventually automatically add to the Slurm cluster configuration.

You could do the inverse and reduce the number of compute nodes to 0.

### Destroying the Cluster

Once you're done working with your cluster and you would like to recover
the resources, in the same folder as `main.tf`, enter:
```
$ terraform destroy
```

As for `apply`, Terraform will output a plan that you will
have to confirm by entering `yes`.

**Beware**, once the cluster is destroyed, nothing will be left, even the
shared storage will be erased.

## Customizing a Live Cluster

Once the cluster is build and provisioned, you are free to modify
its software configuration as you please by connecting to it and
abusing your administrator privileges. If after modifying the
configuration, you think it would be good for Magic Castle to
support your new features, make sure to submit an issue on the
git repo or fork the slurm_cloud_puppet repo and make a pull-request.

We will list here a few common customizations that are not currently
supported directly by Magic Castle, but that are easy to do live.

Most customizations are done from the management node (`mgmt01`).
To connect to the management node, follow these steps:

1. Make sure your SSH key is loaded in your ssh-agent.
2. SSH in your cluster with with forwarding of the authentication
agent connection enabled: `ssh -A centos@cluster_ip`.
3. SSH in the management node : `ssh centos@mgmt01`

### Deactivate Puppet

If you plan to modify configuration files manually, you will need to deactivate
Puppet. Otherwise, you might find out that your modifications to the file
dissapear in a window of 5 minutes.

To avoid this, you will have to delete root crontab. To delete root crontab,
enter : `sudo crontab -r`. This command will need to be run on every node that
runs a service that will be affected by your modification to a configuration
file.

For example, if you plan to modify the `submit.sh` file of JupyterHub, delete
root crontab of the login node.

### Replace the User Accounts Password

A four words password might not be ideal for workshops with new users
who barely know how to type. To replace the randomly-generated
password of the user accounts, follow these steps:

1. Connect to the cluster.
2. Create a variable containing the randomly generated password: `OLD_PASSWD=<random_passwd>`
3. Create a variable containing the new human defined password: `NEW_PASSWD=<human_passwd>`.
This password must respect the FreeIPA password policy. To display the policy enter
```
$ kinit admin # Enter FreeIPA admin password provided by Terraform
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

### Add a User Account

If you would like to add a user account after the cluster is built. Log in the
management node and call:
```
$ IPA_ADMIN_PASSWD=<admin_passwd> IPA_GUEST_PASSWD=<new_user_passwd> \
 /sbin/ipa_create_user.sh <username>
```

### Restrict SSH Access

By default, port 22 of the login node is accessible from the world.
If you know the range of ip addresses that will connect to your cluster,
we strongly recommend you to limit the access to port 22 to this range.

To restrict the ip range, you can use OpenStack web ui.

1. In OpenStack web ui, go to: **Project** → **Network** → **Security Groups**
2. In the Security Groups table, there should be a line named like your cluster
with the suffix `_secgroup`. Click on the corresponding **Managed Rules** button.
3. Find the line with **22 (SSH)** in the **Port Range** column and click on the **Delete Rule** button. Click **Delete Rule** in the following message box.
4. Click on the **Add Rule** button.
5. Select **SSH** in Rule dropping list
6. Define the range of ip addresses in the CIDR box.
7. Click on Add
8. Repeat 3 to 6 if you have multiple ip ranges.

Try to SSH in your cluster. If the connection times out, your ip address is out
of the range of you entered or you made a mystake when defining the range.
Repeat from step 3.

### Increase Jupyter Notebook Job Walltime

**Require Puppet deactivation on the login node**

By default, the Jupyter Notebook jobs started by the cluster have a
maximum walltime of 1 hour. To increase this value or modify
other parameter of the Jupyter Notebook job, edit the following
file on the login node:
`/opt/jupyterhub/etc/submit.sh`

### Add Packages to Jupyter Notebook Kernel

**Require Puppet deactivation on the login node**

On the login node, edit the file
`/opt/jupyterhub/bin/build_venv_tarball.sh` and add new
`pip install` after the ones already in the file. Once the
file is edited, call the following command:

```
$ sudo /opt/jupyterhub/bin/build_venv_tarball.sh
```

### Activate Slurm Oversubscription

**Require Puppet deactivation on the management node**

Sometime, you might be interested in running more jobs than you
have cores available.

To activate Slurm oversubscription, edit `/etc/slurm/slurm.conf`
and add `OverSubscribe=YES` at the end of the partition line that
starts with `PartitionName=`. Once `slurm.conf` is modified, run:
```
sudo scontrol reconfigure
```
to tell Slurm to reload its configuration file.

`OverSubscribe=YES` indicates to Slurm that
CPUs allocated to a job may be shared with other jobs if
each job allows sharing via the `--oversubscribe` option.
Only the CPUs can be oversubscribed. Therefore, the number
of jobs that can run on a node corresponds to the memory available
and the memory allocated per job.

Look at Slurm's documentation to know more:
https://slurm.schedmd.com/cons_res_share.html

#### Run More Notebooks Than Cores

**Require Puppet deactivation on the login node**

Now that oversubscription is activated, you can modify the
JupyterHub submit file to allow notebook jobs to run on
oversubscribed nodes.

Edit `/opt/jupyterhub/etc/submit.sh` and add
```
#SBATCH --oversubscribe
```

Also take time to edit the number of tasks and the amount of
memory per cpu to configure how many notebooks will be able to
run on a single node.

## Customize Magic Castle Terraform Files

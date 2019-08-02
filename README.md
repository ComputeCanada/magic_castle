# Magic Castle Documentation
Version: 3.0

## 1. Setup

To use Magic Castle you will need:
* Terraform (>= 0.12).
* git
* Access to an OpenStack Cloud (e.g.: Arbutus)
* Ability to communicate with the OpenStack API from your computer
* An OpenStack project with room for the allocation of at least
  * 1 floating IP
  * 1 security group
  * 3 volumes
  * 3 instances
  * 6 VCPUs
  * 6 GB of RAM
  * 7 neutron ports
  * 11 security rules

The project can be used to build clusters with commercial cloud, but it implies cost or access to credit.

### 1.1 Setup check

1. Open a terminal
2. Verify the commands were properly installed by looking at the version

    * `git version`
    * `terraform version`

3. Verify you have added your SSH key inside GitLab. Go to https://git.computecanada.ca/profile/keys

## 2. Cloud Cluster Architecture Overview

![Magic Castle Service Architecture](https://docs.google.com/drawings/d/e/2PACX-1vRGFtPevjgM0_ZrkIBQY881X73eQGaXDJ1Fb48Z0DyOe61h2dYdw0urWF2pQZWUTdcNSAM868sQ2Sii/pub?w=1259&amp;h=960)

## 3. Initialization

### 3.1 Main File

1. Go to https://git.computecanada.ca/magic_castle/slurm_cloud.
2. Click on the `examples` folder.
3. Click on the `openstack` folder.
4. Click on `main.tf`

This file contains Terraform modules and outputs. Modules are files that define a set of
resources that will be configured based on the inputs provided in the module block.
Outputs are used to tell Terraform which variables of
our module we would like to be shown on the screen once the resources have been instantiated.

1. Open a Terminal.
2. Create a new folder. Name it after your favourite superhero: `mkdir hulk`
3. Move inside the folder: `cd hulk`
4. Save a copy of the preceding `main.tf` file inside your new folder.

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

**Warning**: the upgrade might not be entirely compatible with your `main.tf`. Confirm
your `main.tf` file is up-to-date by looking at `slurm_cloud` examples folder.

## 4. Configuration

The order of the input parameters we are about to present does not matter, but
we recommend leaving it as it is presented in the examples.

### 4.1 source

The first line of the module block indicates to Terraform where it can find
the `.tf` files that defines the resources that constitutes your future
cluster. We are pointing this variable toward the git repo using the syntax
defined in [Terraform documentation.](https://www.terraform.io/docs/modules/sources.html#generic-git-repository)

The git repository is divided by cloud providers.
If you were to fork this project, you would need to replace the
source value by the link to your own fork.

**Warning**: not all cloud provider modules use the same variables.
You should refer to the examples specific to the cloud provider
you want to use.

### 4.2 cluster_name

Defines the `ClusterName` variable in `slurm.conf` and the name of
the cluster in the Slurm accounting database
([see `slurm.conf` documentation](https://slurm.schedmd.com/slurm.conf.html)).

**Requirements**: Define with lowercase alphanumeric characters and start with a letter.

#### 4.2.1 Post Build Modification Effect

Modifying this variable after the cluster is built leads to a complete
cluster rebuild at next `terraform apply`.

### 4.3 domain

Defines
* the Kerberos realm name when initializing FreeIPA.
* the internal domain name and the resolv.conf search domain as
`int.{cluster_name}.{domain}`

If you own a domain, you can register the login floating IP address
under `{cluster_name}.{domain}` manually with your registrar. An optional
module following the `openstack` module in the example `main.tf` can
register the domain name if your domain's nameservers are administered
by CloudFlare.

#### 4.3.1 Post Build Modification Effect

Modifying this variable after the cluster is built leads to a complete
cluster rebuild at next `terraform apply`.

### 4.4 nb_nodes

Defines how many compute node instances
will be created. This integer can be between 0 and your cloud allocation
instance upper limit minus 2 (you must leave room for a management node and
a login node).

This variable can be modified at any point of your cluster lifetime.
Terraform will manage the creation or destruction of the virtual machines
for you. It is therefore possible to start with 0 compute nodes, build the
cluster, and add more later.

#### 4.4.1 Post Build Modification Effect

Modifying this variable after the cluster is built only affects the number
of compute nodes at next `terraform apply`.

### 4.5 nb_users

Defines how many user accounts will be created in
FreeIPA. Each user account shares the same randomly generated password.
The usernames are defined as `userX` where `X` is a number between 1 and
the value of `nb_users` (zero-padded, i.e.: `user01 if X < 100`, `user1 if X < 10`).

Each user has a home folder on a shared NFS storage hosted by the management
node.

User accounts do not have sudoer privileges. If you wish to use `sudo`,
you will have to login using the sudoer account and the
SSH key defined by `public_key_path`.

If you would like to add a user account after the cluster is built. Log in the
management node and call:
```
$ IPA_ADMIN_PASSWD=<freeipa_passwd> IPA_GUEST_PASSWD=<new_user_passwd> /sbin/ipa_create_user.sh <username>
```

#### 4.5.1 Post Build Modification Effect

Modifying `nb_users` after the cluster is built leads to a rebuild
of the management node at next `terraform apply`.

### 4.6 Storage: type, home_size, project_size, scratch_size

Define the type of network storage and the size of the volumes
for respectively `/home`, `/project` and `/scratch`.

If `type` is set to `nfs`, each volume is mounted on `mgmt01` and
exported with NFS to the login and the compute nodes.

#### 4.6.1 Post Build Modification Effect

Modifying one of these variables after the cluster is built leads to the
destruction of the corresponding volume and attachment and the creation
of a new empty volume and attachment.

### 4.7 public_key_path

Path to an SSH public key file of your choice.
This key will associated with the sudoer account to provide you
administrative access to the cluster.

#### 4.7.1 Post Build Modification Effect

Modifying this variable after the cluster is built leads to a complete
cluster rebuild at next `terraform apply`.

### 4.8 guest_passwd (optional)

**default value**: 4 random words separated by a dot

Defines the password for the guest user accounts instead of using a
randomly generated one.

The password has to have **at least 8 characters**. Otherwise, the guest
account password will not be properly configured.

#### 4.8.1 Post Build Modification Effect

Modifying this variable after the cluster is built leads to a complete
cluster rebuild at next `terraform apply`.

### 4.9 suoder_username (optional)

**default value**: `centos`

Defines the username of the account with sudo privileges. The account
ssh authorized keys are configured with the SSH public key from
`public_key_path`.

#### 4.9.1 Post Build Modification Effect

Modifying this variable after the cluster is built leads to a complete
cluster rebuild at next `terraform apply`.

### 4.10 nb_login (optional)

**default value**: `1`

Defines how many login node instances will be created.

This variable can be modified at any point of your cluster lifetime.
Terraform will manage the creation or destruction of the virtual machines
for you. It is therefore possible to start with 0 login nodess, build the
cluster, and add more later.

#### 4.10.1 Post Build Modification Effect

Modifying this variable after the cluster is built only affects the number
of login nodes at next `terraform apply`.

### 4.11 nb_mgmt (optional)

**default value**: `1`

Defines how many management node instances will be created.

This variable can be modified at any point of your cluster lifetime.
Terraform will manage the creation or destruction of the virtual machines
for you.

**Warning**: All other type of instances depend on the existence of at
least one management node named `mgmt01`. While it is possible to have
`nb_mgmt` equals to 0 and `nb_login` or `nb_nodes` greater than 0, if
you decide to go down that route, you are on your own.

#### 4.11.1 Post Build Modification Effect

Modifying this variable after the cluster is built only affects the number
of management nodes at next `terraform apply`. However, putting that number
to 0 will render other type of nodes almost unusable.

### 4.12 os_image_name

Defines the name of the image that will be used as the
base image for the cluster nodes. For the provisionning to work properly,
this image has to be based on CentOS 7.

You can use custom CentOS 7 image if you wish, but provisioning customization
should be mainly done through Puppet scripting. Image customization is mostly
envisioned as a way to accelerate the provisioning process by applying the
security patches and OS updates in advance.

#### 4.12.1 Post Build Modification Effect
Modifying this variable after the cluster is built leads to a complete
cluster rebuild at next `terraform apply`.

### 4.13 os_flavor_mgmt, os_flavor_login and os_flavor_node

Define the flavor of one of the three types of servers
in the cluster: mgmt, login and node (compute node). A flavor in OpenStack
defines the compute, memory, and storage capacity of an instance.

For `os_flavor_mgmt`, choose a flavor with at least 3 GB of memory.

#### 4.13.1 Post Build Modification Effect

Modifying one of these variables after the cluster is built leads
to a live migration of the instance(s) to the new chosen flavor. The
affected instances will reboot in the process.

### 4.14 os_floating_ips (optional)

**default value**: None

Defines a list of pre-allocated floating ip addresses
that will be assigned to the login nodes. If this variable is left empty,
(e.g. : `[]`) the login nodes' floating ips will be managed by Terraform.

This variable can be useful if you administer your DNS manually and
you would like the keep the same domain name for your cluster at each
build.

#### 4.14.1 Post Build Modification Effect

Modifying this variable after the cluster is built will change the
floating ip assigned to each login node.

### 4.15 os_ext_network (optional)

**default value**: None

Defines the name of the external network that provides the floating
IPs. Define this only if your OpenStack cloud provides multiple
external networks, otherwise, Terraform can find it automatically.

#### 4.15.1 Post Build Modification Effect

Modifying this variable after the cluster is built will change the
floating ip assigned to each login node.

### 4.16 os_int_network (optional)

**default value**: None

Defines the name of the internal network that provides the subnet
on which the instances are connected. Define this only if you
have more than one network defined in your OpenStack project.
Otherwise, Terraform can find it automatically.

#### 4.16.1 Post Build Modification Effect

Modifying this variable after the cluster is built leads to a complete
cluster rebuild at next `terraform apply`.

## 5. Planification

Once your initial cluster configuration is done, you can initiate
a planning phase where you will ask Terraform to communicate with
OpenStack and verify that your cluster can be built as it is
described by the `main.tf` configuration file.

First, you will have to download your OpenStack Open RC
file. It is project-specific and contains the credentials used
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

This command will ask for a password, enter your Compute Canada password.

Terraform should now be able to communicate with OpenStack. To test your
configuration file, enter the following command
```
$ terraform plan
```

This command will validate the syntax of your configuration file and
communicate with OpenStack, but it will not create new resources. It
is only a dry-run. If Terraform does not report any error, you can move
to the next step. Otherwise, read the errors and fix your configuration
file accordingly.

## 6. Deployment

To create the resources defined by your module, enter the following command
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

### 6.1 Deployment Customization

You can modify the `main.tf` at any point of your cluster's life and
apply the modifications while it is running.

**Warning**: Depending on the variables you modify, Terraform might destroy
some or all resources, and create new ones. The effects of modifying each
variable are detailed in the subsections of **Configuration**.

For example, to increase the number of computes nodes by one. Open
`main.tf`, add 1 to `nb_nodes`, save the document and call
```
$ terraform apply
```

Terraform will analyze the difference between the current state and
the future state, and plan the creation of a single new instance. If
you accept the action plan, the instance will be created, provisioned
and eventually automatically add to the Slurm cluster configuration.

You could do the opposite and reduce the number of compute nodes to 0.

## 7. Destruction

Once you're done working with your cluster and you would like to recover
the resources, in the same folder as `main.tf`, enter:
```
$ terraform destroy
```

As for `apply`, Terraform will output a plan that you will
have to confirm by entering `yes`.

**Warning**: once the cluster is destroyed, nothing will be left, even the
shared storage will be erased.

### 7.1 Instance Destruction

It is possible to destroy only the instances and keep the rest of the infrastructure
like the floating ip, the volumes, the generated SSH hostkey, etc.
* To destroy the management node, set `nb_mgmt = 0`;
* To destroy the login node, set `nb_login = 0`;
* To destroy the compute nodes, set `nb_nodes = 0`.

## 8. Online Cluster Configuration

Once the cluster is online and provisioned, you are free to modify
its software configuration as you please by connecting to it and
abusing your administrator privileges. If after modifying the
configuration, you think it would be good for Magic Castle to
support your new features, make sure to submit an issue on the
git repo or fork the slurm_cloud_puppet repo and make a pull request.

We will list here a few common customizations that are not currently
supported directly by Magic Castle, but that are easy to do live.

Most customizations are done from the management node (`mgmt01`).
To connect to the management node, follow these steps:

1. Make sure your SSH key is loaded in your ssh-agent.
2. SSH in your cluster with forwarding of the authentication
agent connection enabled: `ssh -A centos@cluster_ip`.
Replace `centos` by the value of `sudoer_username` if it is
different.
3. SSH in the management node : `ssh mgmt01`

### 8.1 Disable Puppet

If you plan to modify configuration files manually, you will need to disable
Puppet. Otherwise, you might find out that your modifications have disappeared
in a 30-minute window.

puppet is executed every 30 minutes and at every reboot through the puppet agent
service. To disable puppet:
```bash
sudo puppet agent --disable "<MESSAGE>"
```

### 8.2 Replace the User Account Password

A four words password might not be ideal for workshops with new users
who barely know how to type. To replace the randomly generated
password of the user accounts, follow these steps:

1. Connect to the cluster.
2. Create a variable containing the randomly generated password: `OLD_PASSWD=<random_passwd>`
3. Create a variable containing the new human defined password: `NEW_PASSWD=<human_passwd>`.
This password must respect the FreeIPA password policy. To display the policy enter
```
# Enter FreeIPA admin password available in /etc/puppetlabs/puppet/hieradata/data.yaml
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

### 8.3 Add a User Account

To add a user account after the cluster is built, log in `mgmt01` and call:
```
$ IPA_ADMIN_PASSWD=<freeipa_passwd> IPA_GUEST_PASSWD=<new_user_passwd> /sbin/ipa_create_user.sh <username>
```

### 8.4 Restrict SSH Access

By default, port 22 of the login node is accessible from the world.
If you know the range of ip addresses that will connect to your cluster,
we strongly recommend you to limit the access to port 22 to this range.

To restrict the ip range, you can use OpenStack webpage.

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

### 8.5 Add Packages to Jupyter Default Python Kernel

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

## 9. Customize Magic Castle Terraform Files

When we initiated the folder containing the `main.tf` by
calling `terraform init`, Terraform cloned the git repo
linked in our `main.tf` inside a subfolder named
`.terraform/modules`.

Terraform uses md5 hashes to refer to the module, so you
will have to look at the file named `modules.json` to
determine which directory corresponds to which module.

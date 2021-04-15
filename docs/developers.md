# Magic Castle Developer Documentation

## Table of Content

1. [Setup](#1-setup)
2. [Where to start](#2-where-to-start)
3. [Puppet environment](#3-puppet-environment)
4. [Release](#4-release)
5. [Troubleshooting](#5-troubleshooting)

## 1. Setup

To develop for Magic Castle you will need:
* Terraform (>= 0.14.2)
* git
* Access to a Cloud (e.g.: Compute Canada Arbutus)
* Ability to communicate with the cloud provider API from your computer
* A cloud project with enough room for the resource described in section [Magic Caslte Doc 1.1](README.md#11-quotas).
* [optional] [Puppet Development Kit (PDK)](https://puppet.com/docs/pdk/1.x/pdk.html)

## 2. Where to start

The Magic Castle project is defined by Terraform infrastructure-as-code component that
is responsible of generating a cluster architecture in a cloud and a Puppet environment
component that configures the cluster instances based on their role.

If you wish to add device, an instance, add a new networking interface or a filesystem,
you will most likely need to develop some Terraform code. The project structure for
Terraform code is described in the [reference design document](design.md). The document
also describes how one could work with current Magic Castle code to add support for
another cloud provider.

If you wish to add a service to one of the Puppet environments, install a new software,
modify an instance configuration or role, you will most likely need to develop some Puppet
code. The following section provides more details on the Puppet environments available
and how to develop them.

## 3. Puppet environment

Magic Castle Terraform code initialized every instances to be a Puppet agent and an instance
with the tag `puppet` as the Puppet main server. On the Puppet main server, there is a folder
containing the configuration code for the instances of the cluster, this folder is called a
Puppet environment and it is pulled from GitHub during the initial configuration of the Puppet
main server.

The source of that environment is provided to Terraform using the variable `config_git_url`.

A repository describing a Magic Castle Puppet environment must contain at the least
the following files and folders:
```
config_git_repo
┣ Puppetfile
┣ environment.conf
┣ hiera.yaml
┗ data
  ┗ common.yaml
┗ manifests/
  ┗ site.pp
```

- [`Puppetfile`](https://puppet.com/docs/pe/2019.8/puppetfile.html) specifies the Puppet modules that need to be installed in the environment.
- [`environment.conf`](https://puppet.com/docs/puppet/7.5/config_file_environment.html) overrides the primary server default settings for the environment.
- [`hiera.yaml`](https://puppet.com/docs/puppet/7.5/hiera_config_yaml_5.html) configures an ordered list of YAML file data sources.
- `data/common.yaml` is common data source for the instances part of hierarchy defined by `hiera.yaml`.
- `manifests/site.pp` defines how each instance will be configured based on their hostname and/or tags.

An example of a bare-bone Magic Castle Puppet environment is available on GitHub:
[MagicCastle/puppet-environment](https://github.com/MagicCastle/puppet-environment), while the
Puppet environment that replicates a Compute Canada HPC cluster is named
[ComputeCanada/puppet-magic_castle](https://github.com/ComputeCanada/puppet-magic_castle).

### terraform_data.yaml: a bridge between Terraform and Puppet

To provide information on the deployed resources and the value of the input parameters,
Magic Castle Terraform code uploads to the Puppet main server two files:
- `/etc/puppetlabs/code/environment/production/data/terraform_data.yaml`
- `/etc/puppetlabs/code/environment/production/site/profile/facts.d/terraform_data.yaml`

When included in the data hierarchy, `terraform_data.yaml` provides information about the
instances, the volumes and the variables set by the user through the `main.tf` file. The
file has the following structure:
```yaml
---
terraform:
  instances:
    hostname1:
      local_ip: "10.0.0.x"
      public_ip: ""
      tags: ["tag_1"]
      hostkeys:
        rsa: ""
  volumes:
    volume_tag1:
      volume_1:
        - "/dev/disk/by-id/123-*"
      volume_2:
        - "/dev/disk/by-id/123-abc-*"
  tag_ip:
    tag_1: 
      - 10.0.0.x
  data:
    cluster_name: ""
    consul_token: ""
    domain_name: ""
    freeipa_passwd: ""
    guest_passwd: ""
    munge_key: ""
    nb_users: ""
    sudoer_username: ""
```

The value provided by this data source can be accessed in Puppet by using the `lookup()` function.
For example, to access an instance's list of tags:
```puppet
lookup("terraform.instances.${::hostname}.tags")
```
The data source can also be used to define a key in another data source YAML file by using the
`alias()` function. For example, to define the number of guest accounts using the value of `nb_user`,
we could add this to `common.yaml`
```
profile::accounts::guests::nb_accounts: "%{alias('terraform.data.nb_users')}"
```

## 5. Release

To build a release, use the script `release.sh` located at the root of Magic Castle git repo.
```
Usage: release.sh VERSION [provider ...]
```
The script creates a folder named `releases` where it was called.

The `VERSION` argument is expected to correspond to git tag in the `puppet-magic_castle` repo.
It could also be a branch name or a commit. If the provider optional argument is left blank,
release files will be built for all providers currently supported by Magic Castle.

Examples:

- Building a release for OpenStack with the puppet repo main branch:
    ```
    $ ./release.sh main openstack
    ```
- Building a release for GCP with the latest Terraform and cloud-init, and version 5.8 of puppet
Magic Castle:
    ``` 
    $ ./release.sh 5.8 gcp
    ```
- Building a release for Azure and OVH with the latest Terraform and cloud-init, and version 5.7 of puppet
Magic Castle:
    ```
    $ ./release.sh 5.7 azure ovh
    ```

## 4. Troubleshooting


### 4.1 cloud-init

To test new additions to `puppet.yaml`, it is possible to
execute cloud-init phases manually. There are four steps that can be executed sequentially: init local, init
modules config and modules final. Here are the corresponding commands to execute each step:
```
cloud-init init --local
cloud-init init
cloud-init modules --mode=config
cloud-init modules --mode=final
```

It is also possible to clean a cloud-init execution and have it execute again at next reboot. To do so, enter
the following command:
```
cloud-init clean
```
Add `-r` to the previous command to reboot the instance once cloud-init has finishing cleaning.
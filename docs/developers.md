# Magic Castle Developer Documentation

## Table of Content

1. [Setup](#1-setup)
2. [Puppet configuration management repo](#2-puppet-configuration-management-repo)
3. [Release](#3-release)
4. [Troubleshooting](#4-troubleshooting)

## 1. Setup

To develop for Magic Castle you will need:
* Terraform (>= 0.14.2)
* git
* Access to a Cloud (e.g.: Compute Canada Arbutus)
* Ability to communicate with the cloud provider API from your computer
* A cloud project with enough room for the resource described in section [Magic Caslte Doc 1.1](README.md#11-quotas).
* [optional] [Puppet Development Kit (PDK)](https://puppet.com/docs/pdk/1.x/pdk.html)


## 2. Puppet configuration management repo

This repository must contain at the least the following files and folders:
```
config_git_repo
┣ Puppetfile
┗ data/
  ┗ terraform_data.yaml.tmpl
┣ environment.conf
┣ hiera.yaml
┗ manifests/
  ┗ site.pp
┗ site/
  ┗ profile/
    ┗ facts.d
      ┗ terraform_facts.yaml.tmpl
```

## 3. Release

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

To test new additions to `cloud-init/puppet.yaml`, it is possible to
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
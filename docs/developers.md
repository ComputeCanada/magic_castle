# Magic Castle Developer Documentation

## Table of Content

1. [Setup](#1-setup)
2. [Configuration](#2-configuration)
3. [Release](#3-release)

## 1. Setup

To develop for Magic Castle you will need:
* Terraform (>= 0.12.21)
* git
* Access to a Cloud (e.g.: Compute Canada Arbutus)
* Ability to communicate with the cloud provider API from your computer
* A cloud project with enough room for the resource described in section [Magic Caslte Doc 1.1](README.md#11-quotas).
* [optional] [Puppet Development Kit (PDK)](https://puppet.com/docs/pdk/1.x/pdk.html)


## 2. Configuration

### 2.1 puppetenv_git and puppetenv_rev (**optional**)

**default value**: `master`

Package installation and configuration - provisioning - of the cluster
is mainly done by [Puppet](https://en.wikipedia.org/wiki/Puppet_(software)).
Magic Castle provides Puppet environments as a git repo. The puppet modules,
site configuration and hieradata are defined in the git repo
[puppet-magic_castle repo](https://github.com/ComputeCanada/puppet-magic_castle/).

When you download a release of Magic Castle, the `puppetenv_git` variable point to
the `puppet-magic_castle` git repo and `puppetenv_rev` to a specific tag. You can
fork the repo and configure your cluster as you would like by making `puppetenv_git`
points toward your own repo. `puppetenv_rev` points to the `master` branch when
using the Magic Castle git repo instead of the release archive.

To get more details on the configuration of each host per arrangement,
look at the [puppet-magic_castle repo](https://github.com/ComputeCanada/puppet-magic_castle/).

#### 2.1.1 Post Build Modification Effect

Modifying this variable after the cluster is built leads to a complete
cluster rebuild at next `terraform apply`.

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

- Building a release for OpenStack with the puppet repo master branch:
    ```
    $ ./release.sh master openstack
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

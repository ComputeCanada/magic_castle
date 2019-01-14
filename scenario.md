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

The first line of the module block indicates to Terraform where it can find
the Terraform files that defines the resources that constitutes your future
cluster. The git repository of the project is divided in cloud provider.
Since we are using OpenStack, the source corresponds to the the openstack
folder. If you were to fork this project, you would need to replace the
source value by the link to your own fork.


# Magic Castle

[![Build Status](https://travis-ci.com/ComputeCanada/magic_castle.svg?branch=master)](https://travis-ci.com/ComputeCanada/magic_castle)

[Compute Canada](https://www.computecanada.ca/) provides HPC infrastructure and support to every academic research institution in Canada. Compute Canada [uses CVMFS](https://docs.computecanada.ca/wiki/Accessing_CVMFS), a software distribution system [developed at CERN](https://cernvm.cern.ch/portal/filesystem), to make the Compute Canada research software stack available on its HPC clusters, and anywhere else with internet access. This enables replication of the Compute Canada experience outside of its physical infrastructure.

From these new possibilities emerged an open-source software project named Magic Castle, which aims to recreate the Compute Canada user experience in public clouds. Magic Castle uses the open-source software [Terraform](https://www.terraform.io) and HashiCorp Language (HCL) to define the virtual machines, volumes, and networks that are required to replicate a virtual HPC infrastructure. The infrastructure definition is packaged as a Terraform module that users can customize as they require. After deployment, the user is provided with a complete HPC cluster software environment including a Slurm scheduler, a Globus Endpoint, JupyterHub, LDAP, DNS, and over 3000 research software applications compiled by experts with [EasyBuild](https://github.com/easybuilders/easybuild). Magic Castle is compatible with AWS, Microsoft Azure, Google Cloud, OpenStack, and OVH.

## Setup

- Install [Terraform >= 0.12.21](https://www.terraform.io/downloads.html)
- Download the [latest release of Magic Castle](https://github.com/ComputeCanada/magic_castle/releases) for the cloud provider you wish to use.
- Uncompress the release
- Follow the instructions 
  - [OpenStack Cloud (Compute Canada)](openstack/README.md)
  - [Amazon Web Services (AWS)](aws/README.md)
  - [Microsoft Azure](azure/README.md)
  - [Google Cloud Platform (GCP)](gcp/README.md)
  - [OVH Public Cloud (OVH)](ovh/README.md)
- For more details, refer to [Magic Castle Documentation](docs)

## How Magic Castle Works

This software project integrates multiple parts that come into play at 
different steps of spawning the cluster. The following list 
enumerates the steps involved in order for users to better
grasp what is happening when they create clusters.

We will refer to the user of Magic Castle as the operator.

1. After downloading the latest release of the cloud provider of choice
and adapting the Terraform `main.tf` file, the operator launches 
`terraform apply` and accepts the proposed plan.

2. Terraform fetches the template hieradata yaml file from the 
puppet-magic_castle repo indicated by `puppetenv_git`. The version 
of that file corresponds to the value of `puppetenv_rev`. This template 
is read by terraform and variable placeholders are replaced by the values 
inferred from the values prescribed in `main.tf`.

3. Terraform communicates with the cloud provider REST API and requests the creation of the virtual machines.

4. For each virtual machine creation request, Magic Castle
provides a [cloud-init](https://cloudinit.readthedocs.io/en/latest/) file. This
file is used to initialize the virtual machine base configuration and installs 
puppet agent. The cloud-init file of the management node (`mgmt1`) also installs and configures
a puppetmaster. 

5. The puppet agents communicate with the puppetmaster to retrieve
and apply their configuration based on their hostnames. 

## Talks, slides and videos

- [FOSDEM 2020 - Magic Castle: Terraforming the Cloud for HPC](https://fosdem.org/2020/schedule/event/magic_castle/)

## List of other cloud HPC cluster open-source projects

- [ACRC Cluster in the cloud](https://github.com/ACRC/cluster-in-the-cloud) [GCP, Oracle]
- [AWS ParallelCluster](https://github.com/aws/aws-parallelcluster) [AWS]
- [Elasticluster](https://github.com/elasticluster/elasticluster) [AWS, GCP, OpenStack]
- [Slurm on Google Platform](https://github.com/SchedMD/slurm-gcp) [GCP]

## Contributing / Customizing

Refer to [Magic Castle developper documentation](docs/developers.md).

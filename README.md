# Magic Castle

<!-- markdown-link-check-disable-next-line -->
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.4895357.svg)](https://doi.org/10.5281/zenodo.4895357)
[![Build Status](https://github.com/ComputeCanada/magic_castle/actions/workflows/test.yaml/badge.svg)](https://github.com/ComputeCanada/magic_castle/actions/workflows/test.yaml)

<img src="https://github.com/computecanada/magic_castle/raw/assets/logo.png" width="150">

[The Digital Research Alliance of Canada](https://www.alliancecan.ca/) provides HPC infrastructure and support to every academic research institution in Canada. The Alliance [uses CVMFS](https://docs.alliancecan.ca/wiki/Accessing_CVMFS), a software distribution system [developed at CERN](https://cernvm.cern.ch/fs/), to make its research software stack available on its HPC clusters, and anywhere else with internet access. This enables replication of the user experience outside of The Alliance physical infrastructure.

From these new possibilities emerged an open-source software project named Magic Castle, which aims to recreate the HPC user experience in public clouds. Magic Castle uses the open-source software [Terraform](https://www.terraform.io) and HashiCorp Language (HCL) to define the virtual machines, volumes, and networks that are required to replicate a virtual HPC infrastructure. The infrastructure definition is packaged as a Terraform module that users can customize as they require. After deployment, the user is provided with a complete HPC cluster software environment including a Slurm scheduler, a Globus Endpoint, JupyterHub, LDAP, DNS, and over 3000 research software applications compiled by experts with [EasyBuild](https://github.com/easybuilders/easybuild). Magic Castle is compatible with AWS, Microsoft Azure, Google Cloud, OpenStack, and OVH.

## Setup

- Install [Terraform](https://releases.hashicorp.com/terraform/) (>= 1.4.0)
- Download the [latest release of Magic Castle](https://github.com/ComputeCanada/magic_castle/releases) for the cloud provider you wish to use.
- Uncompress the release
- Follow the instructions
  - [OpenStack Cloud](openstack/README.md)
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
and adapting the main configuration file, the operator launches
Terraform and accepts the proposed plan.
2. Terraform communicates with the cloud provider REST API and requests
the creation of the virtual machines.
3. For each virtual machine creation request, Magic Castle
provides a [cloud-init](https://cloudinit.readthedocs.io/en/latest/) file. This
file is used to initialize the virtual machine base configuration and installs
puppet agent. The cloud-init file of the `puppet` tagged virtual machine installs
and configures a Puppet primary server.
4. Terraform uploads on the Puppet primary server instance a YAML file containing
information about the roles of each instances specified as tags.
5. The Puppet agents communicate with the Puppet primary server to retrieve
and apply their configuration based on the tags defined in the preceding YAML file.

## Talks, slides and videos

- [FOSDEM 2020 - Magic Castle: Terraforming the Cloud for HPC](https://fosdem.org/2020/schedule/event/magic_castle/) (2020-02-02)
- [EasyBuild User Meeting 2021 - Magic Castle: Terraforming the Cloud for HPC](https://www.youtube.com/watch?v=54ph7f2-AL4) (2021-01-27)
- [Campus Research Computing Consortium - Clusters in the Sky: How Canada is Building Beyond Iaas Cloud with Magic Castle](https://www.youtube.com/watch?v=jWCyUeGmm-8) (2021-05-20)
- [EESSI User Meeting 2022 - Magic Castle: Preview of MC 12](https://www.youtube.com/watch?v=XGnxbIHJLmw&list=PL6_PkP_6pUtb7_tovj1V__y4ii_AjhroJ&index=6) (2022-09-14)
- [HashiTalks Québec 2022 - Magic Castle: Le CIP à l'échelle grâce à Terraform Cloud](https://www.youtube.com/watch?v=3Mg4gMmkktM) (2022-09-29)
- [SIGHPC Education - Magic Castle: Terraforming the cloud to teach HPC](https://sighpceducation.acm.org/events/magic_castle/) (2024-02-08)

## List of other cloud HPC cluster open-source projects

- [AWS ParallelCluster](https://github.com/aws/aws-parallelcluster) [AWS]
- [Cluster in the cloud](https://github.com/clusterinthecloud) [AWS, GCP, Oracle]
- [Elasticluster](https://github.com/elasticluster/elasticluster) [AWS, GCP, OpenStack]
- [Google Cluster Toolkit](https://github.com/GoogleCloudPlatform/cluster-toolkit) [GCP]
- [illume-v2](https://github.com/jamierajewski/illume-v2/) [OpenStack]
- [NVIDIA DeepOps](https://github.com/NVIDIA/deepops) [Ansible playbooks only]
- [StackHPC Ansible Role OpenHPC](https://github.com/stackhpc/ansible-role-openhpc) [Ansible Role for OpenStack]


> When I think about the DevOps landscape, we have so many people just like chefs in a restaurant that are experimenting with different ways of doing things. Once they get it, then they create those recipes. Those recipes in our world is source code. [...] That's why we will always have duplicates and similar projects, because there's going to be one ingredient that's going to be slightly different to make you preferred over something else

[Kelsey Hightower, Sourcegraph Podcast, Episode 16, 2020](https://web.archive.org/web/20240527182945/https://sourcegraph.com/podcast/kelsey-hightower)

## Contributing / Customizing

Refer to the [reference design](docs/design.md) and the [developer documentation](docs/developers.md).

# Magic Castle

[![Build Status](https://travis-ci.com/ComputeCanada/magic_castle.svg?branch=master)](https://travis-ci.com/ComputeCanada/magic_castle)

[Compute Canada](https://www.computecanada.ca/) provides HPC infrastructures and support to every academic research institution in Canada. In recent years, Compute Canada has started distributing research software to its HPC clusters using with CERN software distribution service, [CVMFS](https://cernvm.cern.ch/portal/filesystem). This opened the possibility for accessing the software from almost any location and therefore allow the replication of the Compute Canada experience outside of its physical infrastructure.

From these new possibilities emerged an open-source software project named Magic Castle, which aims to recreate the Compute Canada user experience in public clouds. Magic Castle uses the open-source software [Terraform](https://www.terraform.io) and HashiCorp Language (HCL) to define the virtual machines, volumes, and networks that are required to replicate a virtual HPC infrastructure. The infrastructure definition is packaged as a Terraform module that users can customize as they require. Once their cluster is deployed, the user is provided with a complete HPC cluster software environment including a Slurm scheduler, a Globus Endpoint, JupyterHub, LDAP, DNS, and over 3000 research software compiled by experts with EasyBuild. Magic Castle is compatible with AWS, Microsoft Azure, Google Cloud, OpenStack, and OVH.

## Setup

- Install [Terraform >= 0.12](https://www.terraform.io/downloads.html)
- Download the [latest release of Magic Castle](https://github.com/ComputeCanada/magic_castle/releases) for the cloud provider you wish to use.
- Uncompress the release
- Follow the instructions 
  - [OpenStack Cloud (Compute Canada)](openstack/README.md)
  - [Amazon Web Services (AWS)](aws/README.md)
  - [Microsoft Azure](azure/README.md)
  - [Google Cloud Platform (GCP)](gcp/README.md)
  - [OVH Public Cloud (OVH)](ovh/README.md)
- For more details, refer to [Magic Castle Documentation](docs)

## Using a DNS Service

### CloudFlare

1. Uncomment the `dns` module for CloudFlare in your `main.tf`.
2. Uncomment the `output "dns"` block.
3. In the `dns` module, configure the variable `email` with your email address. This will be used to generate the Let's Encrypt certificate.
4. Download and install the CloudFlare Terraform module: `terraform init`.
5. Export the following environment variables `CLOUDFLARE_EMAIL` and `CLOUDFLARE_API_KEY`, where `CLOUDFLARE_EMAIL` is your Cloudflare account email adress and `CLOUDFLARE_API_KEY` is your account Global API Key available in your [CloudFlare profile](https://dash.cloudflare.com/profile/api-tokens).
6. Execute `terraform apply`.

#### CloudFlare API Token

If you prefer using an API token instead of the global API key, you will need to configure a token with the following four permissions with [CloudFlare API Token interface](https://dash.cloudflare.com/profile/api-tokens).

| Section | Subsection | Permission|
| ------------- |-------------:| -----:|
| Account | Account Settings | Read|
| Zone | Zone Settings | Read|
| Zone | Zone | Read|
| Zone | DNS | Write|

Instead of step 5, export only `CLOUDFLARE_API_TOKEN`, `CLOUDFLARE_ZONE_API_TOKEN`, and `CLOUDFLARE_DNS_API_TOKEN` equal to the API token generated previously.

### Google Cloud

**requirement**: Install the [Google Cloud SDK](https://cloud.google.com/sdk/docs/downloads-interactive)

1. Login to your Google account with gcloud CLI : `gcloud auth application-default login`
2. Uncomment the `dns` module for Google Cloud in your `main.tf`.
3. Uncomment the `output "hostnames"` block.
4. In `main.tf`'s `dns` module, configure the variable `email` with your email address. This will be used to generate the Let's Encrypt certificate.
5. In `main.tf`'s `dns` module, configure the variables `project_name` and `zone_name`
with their respective value as defined by your Google Cloud project.
6. Download and install the Google Cloud Terraform module: `terraform init`.
7. Execute `terraform apply`.

## Verifying the cluster state

On the login node :
- Verify SLURM cluster state: `sinfo`. You should see the number of nodes defined in `main.tf`.
and all nodes should have an idle state.
- Verify JupyterHub state: `systemctl status jupyterhub`. It should be active.
- Verify you can run interactive jobs: `salloc`
- Verify the home were created: `ls /home`. You should see as many home as there are guest account + centos account.

If you used the CloudFlare DNS Service
- Verify the domain name: go to https://${domain_name}. It should be JupyterHub login page.

## How Magic Castle Works

This software project integrates multiple parts that come into play at 
different steps of the cluster spawning. The following list tries to 
enumerate the steps and the parts involved in order for the users to better
grasp what is happening when they create clusters.

We will refer to the user of Magic Castle as the operator.

1. After downloading the latest release of his cloud provider of choice
and adapting the Terraform `main.tf` file, the operator launches 
`terraform apply` and accept the proposed plan.

2. Terraform fetches the template hieradata yaml file from the 
puppet-magic_castle repo indicated by `puppetenv_git`. The version 
of that file corresponds to the value of `puppetenv_rev`.

This template is read by terraform and variable placeholders are
replaced by the values infers from the values prescribed in `main.tf`.

3. Terraform communicates with the cloud provider REST API and ask
for the creation of the virtual machines.

4. For each request of virtual machine creation, Magic Castle
provides a [cloud-init](https://cloudinit.readthedocs.io/en/latest/) file. This
file is used to initialize the virtual base configuration and install 
puppet agent.

The cloud-init file of the management node (`mgmt1`) also installs and configures
a puppetmaster. The puppet agents will communicate with the puppemaster to retrieve
their configuration based on their hostname. 
5. 

## Contributing / Customizing

Refer to [Magic Castle developper documentation](docs/developers.md).
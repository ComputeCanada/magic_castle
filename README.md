# Terraform Magic Castle

## Setup

- Install [Terraform >= 0.12](https://www.terraform.io/downloads.html)
- Download the latest release of Magic Castle for the cloud provider you wish to use.
- Uncompress the release
- Follow the instructions 
  - [OpenStack Cloud (Compute Canada)](openstack/README.md)
  - [Amazon Web Services (AWS)](aws/README.md)
  - [Microsoft Azure](azure/README.md)
  - [Google Cloud Platform (GCP)](gcp/README.md)
  - [OVH Public Cloud (OVH)](ovh/README.md)

## Using Cloudflare DNS Service

1. Uncomment the `dns` module in your `main.tf`.
2. Download and install the CloudFlare module: `terraform init`.
2. Export the following environment variables `CLOUDFLARE_EMAIL`, `CLOUDFLARE_TOKEN` and `CLOUDFLARE_API_KEY`. TOKEN and API_KEY contain the same value, different providers expect different environment variables.
3. Run `terraform apply`.

## Verifying the cluster state

On the login node :
- Verify SLURM cluster state: `sinfo`. You should see the number of nodes defined in `main.tf`.
and all nodes should have an idle state.
- Verify JupyterHub state: `systemctl status jupyterhub`. It should be active.
- Verify you can run interactive jobs: `salloc`
- Verify the home were created: `ls /home`. You should see as many home as there are guest account + centos account.

If you used the CloudFlare DNS Service
- Verify the domain name: go to https://${domain_name}. It should be JupyterHub login page.

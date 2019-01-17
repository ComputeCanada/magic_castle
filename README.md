# Terraform Slurm Cloud

## Local Setup

- Install [Terraform](https://www.terraform.io/downloads.html)

## OpenStack Cloud

1. Create a new folder : `mkdir my_new_cluster`.
2. Copy an example `main.tf` from the [openstack example folder](https://git.computecanada.ca/fafor10/slurm_cloud/tree/master/examples/openstack).
3. Download your project openrc file from the OpenStack _Access and security_ section.
4. Source your project openrc file : `source _project_-openrsh.sh`.
5. Initiate the Terraform state : `terraform init`.
6. Adapt the cluster variables in the `main.tf` file (i.e.: # guest accounts, # nodes, domain name, ssh key, etc).
7. Verify the Terraform plan : `terraform plan`.
8. Apply the Terraform plan : `terraform apply`.

To tear down the cluster, from the `my_new_cluster` folder, call: `terraform destroy`.

## Amazon Web Services

1. Create a new folder : `mkdir my_new_cluster`.
2. Copy an example `main.tf` from the [aws example folder](https://git.computecanada.ca/fafor10/slurm_cloud/tree/master/examples/aws).
3. Export the following environment variables : `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`.
4. Initiate the Terraform state : `terraform init`.
5. Adapt the cluster variables in the `main.tf` file (i.e.: # guest accounts, # nodes, domain name, ssh key, etc).
6. Verify the Terraform plan : `terraform plan`.
7. Apply the Terraform plan : `terraform apply`.

To tear down the cluster, from the `my_new_cluster` folder, call: `terraform destroy`.

## Azure

1. Create a new folder : `mkdir my_new_cluster`.
2. Copy the example `main.tf` from the [azure example folder](https://git.computecanada.ca/fafor10/slurm_cloud/tree/master/examples/azure).
3. Go in the azure project folder : `cd slurm_cloud-1.0*/azure`.
4. Install [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) if not already installed : `pip install azure-cli`.
5. Login to Azure and follow the instructions : `az login`.
6. Initiate the Terraform state : `terraform init`.
7. Adapt the cluster variables in the `main.tf` file (i.e.: # guest accounts, # nodes, domain name, ssh key, etc).
8. Verify the Terraform plan : `terraform plan`.
9. Apply the Terraform plan : `terraform apply`.

To tear down the cluster, from the `my_new_cluster` folder, call: `terraform destroy`.

## GCP

1. Create a new folder : `mkdir my_new_cluster`.
2. Copy the example `main.tf` from the [gcp example folder](https://git.computecanada.ca/fafor10/slurm_cloud/tree/master/examples/gcp).
3. Install the [Google Cloud SDK](https://cloud.google.com/sdk/install)
4. Login to your Google account : `gcloud auth application-default login`
5. Initiate the Terraform state : `terraform init`.
6. Adapt the cluster variables in the `main.tf` file (i.e.: # guest accounts, # nodes, domain name, ssh key, etc).
7. Verify the Terraform plan : `terraform plan`.
8. Apply the Terraform plan : `terraform apply`.

To tear down the cluster, from the `my_new_cluster` folder, call: `terraform destroy`.

## OVH

1. Create a new folder : `mkdir my_new_cluster`.
2. Copy an example `main.tf` from the [ovh example folder](https://git.computecanada.ca/fafor10/slurm_cloud/tree/master/examples/ovh).
3. Download your project OpenStack RC File v3 (v2 won't work) from the [OVH OpenStack interface](https://horizon.cloud.ovh.net/project/) at the top right corner of the page.
4. Source your project openrc file : `source _project_-openrc.sh`.
5. Initiate the Terraform state : `terraform init`.
6. Adapt the cluster variables in the `main.tf` file (i.e.: # guest accounts, # nodes, domain name, ssh key, etc).
7. Verify the Terraform plan : `terraform plan`.
8. Apply the Terraform plan : `terraform apply`.

To tear down the cluster, from the `my_new_cluster` folder, call: `terraform destroy`.

## Using Cloudflare DNS Service

1. Uncomment the `dns` module in your `main.tf`.
2. Download and install the CloudFlare module: `terraform init`.
2. Export the following environment variables `CLOUDFLARE_EMAIL` and `CLOUDFLARE_TOKEN`.
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

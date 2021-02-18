# Azure

1. Install [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) if not already installed : `pip install azure-cli`.
2. Login to Azure and follow the instructions : `az login`.
3. Download the latest release of Magic Castle for Azure.
4. Unpack the release.
5. Adapt the cluster variables in `main.tf` file (i.e.: # guest accounts, # nodes, domain name, ssh key, etc).
6. In a terminal, change your current directory to the directory containing `main.tf`.
7. Initiate the Terraform state : `terraform init`.
8. Verify the Terraform plan : `terraform plan`.
9. Apply the Terraform plan : `terraform apply`.

To tear down the cluster, call: `terraform destroy`.
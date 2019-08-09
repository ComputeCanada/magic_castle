# Azure

1. Install [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) if not already installed : `pip install azure-cli`.
2. Login to Azure and follow the instructions : `az login`.
3. Initiate the Terraform state : `terraform init`.
4. Adapt the cluster variables in the `main.tf` file (i.e.: # guest accounts, # nodes, domain name, ssh key, etc).
5. Verify the Terraform plan : `terraform plan`.
6. Apply the Terraform plan : `terraform apply`.

To tear down the cluster, call: `terraform destroy`.
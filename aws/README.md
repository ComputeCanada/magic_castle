# Amazon Web Services

1. Export the following environment variables : `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`.
2. Download the latest release of Magic Castle for AWS.
3. Unpack the release.
4. Adapt the cluster variables in `main.tf` file (i.e.: # guest accounts, # nodes, domain name, ssh key, etc).
5. In a terminal, change your current directory to the directory containing `main.tf`.
6. Initiate the Terraform state : `terraform init`.
7. Verify the Terraform plan : `terraform plan`.
8. Apply the Terraform plan : `terraform apply`.

To tear down the cluster, call: `terraform destroy`.

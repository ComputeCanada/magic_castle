# Amazon Web Services

1. Export the following environment variables : `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`.
2. Initiate the Terraform state : `terraform init`.
3. Adapt the cluster variables in the `main.tf` file (i.e.: # guest accounts, # nodes, domain name, ssh key, etc).
4. Verify the Terraform plan : `terraform plan`.
5. Apply the Terraform plan : `terraform apply`.

To tear down the cluster, call: `terraform destroy`.
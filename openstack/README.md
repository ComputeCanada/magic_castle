# OpenStack Cloud

1. Download your project openrc file from the OpenStack _Access and security_ section.
2. Source your project openrc file : `source _project_-openrsh.sh`.
3. Initiate the Terraform state : `terraform init`.
4. Adapt the cluster variables in the `main.tf` file (i.e.: # guest accounts, # nodes, domain name, ssh key, etc).
5. Verify the Terraform plan : `terraform plan`.
6. Apply the Terraform plan : `terraform apply`.

To tear down the cluster, call: `terraform destroy`.
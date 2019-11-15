# OpenStack Cloud

1. Download your project OpenStack RC file from the OpenStack Project _API Access_ page _i.e._: `OpenStack RC File (Identity API v3)`.
2. Source your project openrc file : `source _project_-openrc.sh`.
3. Download the latest release of Magic Castle for OpenStack.
4. Unpack the release.
5. Adapt the cluster variables in `main.tf` file (i.e.: # guest accounts, # nodes, domain name, ssh key, etc).
6. In a terminal, change your current directory to the directory containing `main.tf`.
7. Initiate the Terraform state : `terraform init`.
8. Verify the Terraform plan : `terraform plan`.
9. Apply the Terraform plan : `terraform apply`.

To tear down the cluster, call: `terraform destroy`.
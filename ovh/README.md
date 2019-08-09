# OVH

1. Download your project OpenStack RC File v3 (v2 won't work) from the [OVH OpenStack interface](https://horizon.cloud.ovh.net/project/) at the top right corner of the page.
2. Source your project openrc file : `source _project_-openrc.sh`.
3. Initiate the Terraform state : `terraform init`.
4. Adapt the cluster variables in the `main.tf` file (i.e.: # guest accounts, # nodes, domain name, ssh key, etc).
5. Verify the Terraform plan : `terraform plan`.
6. Apply the Terraform plan : `terraform apply`.

To tear down the cluster, call: `terraform destroy`.
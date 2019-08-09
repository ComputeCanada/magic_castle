# GCP

1. Install the [Google Cloud SDK](https://cloud.google.com/sdk/install)
2. Login to your Google account : `gcloud auth application-default login`
3. Initiate the Terraform state : `terraform init`.
4. Adapt the cluster variables in the `main.tf` file (i.e.: # guest accounts, # nodes, domain name, ssh key, etc).
5. Verify the Terraform plan : `terraform plan`.
6. Apply the Terraform plan : `terraform apply`.

To tear down the cluster, call: `terraform destroy`.
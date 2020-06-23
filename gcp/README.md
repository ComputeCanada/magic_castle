# GCP

1. Install the [Google Cloud SDK](https://cloud.google.com/sdk/docs/downloads-interactive)
2. Login to your Google account : `gcloud auth application-default login`
3. Download the latest release of Magic Castle for Google Cloud.
4. Unpack the release.
5. Adapt the cluster variables in `main.tf` file (i.e.: # guest accounts, # nodes, domain name, ssh key, etc).
5. In a terminal, change your current directory to the directory containing `main.tf`.
6. Initiate the Terraform state : `terraform init`.
7. Verify the Terraform plan : `terraform plan`.
8. Apply the Terraform plan : `terraform apply`.

To tear down the cluster, call: `terraform destroy`.
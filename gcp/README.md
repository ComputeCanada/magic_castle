# GCP

Refer to [Magic Castle Documentation](https://github.com/ComputeCanada/magic_castle/tree/main/docs) for a complete step-by-step guide.

TL;DR:
1. Install the [Google Cloud SDK](https://cloud.google.com/sdk/docs/downloads-interactive)
2. Login to your Google account : `gcloud auth application-default login`
3. Download the [latest release of Magic Castle for Google Cloud](https://github.com/ComputeCanada/magic_castle/releases/latest).
4. Unpack the release.
5. Adapt the [parameters](https://github.com/ComputeCanada/magic_castle/tree/main/docs#4-configuration) in `main.tf` file.
6. In a terminal, change your current directory to the directory containing `main.tf`.
7. Initiate the Terraform state : `terraform init`.
8. Verify the Terraform plan : `terraform plan`.
9. Apply the Terraform plan : `terraform apply`.

To tear down the cluster, call: `terraform destroy`.
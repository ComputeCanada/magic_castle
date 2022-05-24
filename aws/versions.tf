
terraform {
  required_version = ">= 1.2.1"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 4.10.0"
    }
  }
}

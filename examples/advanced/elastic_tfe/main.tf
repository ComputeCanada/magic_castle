terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 4.0"
    }
  }
}

provider "github" {}
provider "tfe" {}

variable "organization" {
  type        = string
  description = "Name of your organization in Terraform Cloud"
}
variable "hostname" {
  type        = string
  description = "Hostname of the Magic Castle cluster to build"
}
variable "sshkey" {
  type        = string
  description = "Personal SSH key to connect to the cluster"
}
variable "cloud" {
  type        = string
  description = "Cloud provider to use"
  validation {
     condition     = contains(["openstack", "ovh"], var.cloud)
     error_message = "Cloud provider must be one of openstack or ovh"
  }
}
variable "dns" {
  type        = string
  default     = ""
  description = "DNS provider to use"
  validation {
     condition     = contains(["cloudflare", "gcloud", ""], var.dns)
     error_message = "DNS provider must be one of cloudflare, gcloud or empty"
  }
}
variable "github_token" {
  type        = string
  description = "GitHub token to use"
}
variable "tfe_token" {
  type        = string
  description = "Terraform Cloud token to use"
  default     = ""
}

locals {
    cluster_name = split(".", var.hostname)[0]
    domain = trimprefix(var.hostname, "${local.cluster_name}.")
}

resource "tfe_oauth_client" "oauth" {
  name             = "my-github-oauth-client"
  organization     = var.organization
  api_url          = "https://api.github.com"
  http_url         = "https://github.com"
  service_provider = "github"
  oauth_token      = var.github_token
}

resource "github_repository" "repo" {
  name        = var.hostname
  description = "${var.hostname} repository"
  auto_init     = true

  visibility    = "private"
  has_projects  = false
  has_wiki      = false
  has_downloads = false
}

resource "tfe_workspace" "workspace" {
  name         = replace(var.hostname, ".", "-")
  organization = var.organization
  auto_apply   = false
  tag_names    = ["magic_castle", "slurm", "elastic"]
  vcs_repo {
    identifier     = github_repository.repo.full_name
    oauth_token_id = tfe_oauth_client.oauth.oauth_token_id
    branch         = "main"
  }
}

resource "tfe_variable" "draft_exclusion" {
  key          = "draft_exclusion"
  value        = "[]"
  category     = "terraform"
  hcl          = true
  workspace_id = tfe_workspace.workspace.id
  description  = "Slurm draft compute note exclusion list, control by Slurm"
}

resource "github_repository_file" "main" {
  repository          = github_repository.repo.name
  branch              = "main"
  file                = "main.tf"
  content             = templatefile("templates/${var.cloud}.tftpl", {
    cluster_name = local.cluster_name,
    domain       = local.domain
    dns_provider = var.dns
    sshkey       = var.sshkey
    varname      = tfe_variable.draft_exclusion.key
  })
  commit_message      = "Add main.tf"
  overwrite_on_create = true
}

resource "github_repository_file" "data" {
  repository          = github_repository.repo.name
  branch              = "main"
  file                = "data.yaml"
  content             = templatefile("templates/data.yaml.tftpl", {
    tfe_token    = var.tfe_token
    workspace_id = tfe_workspace.workspace.id,
    varname      = tfe_variable.draft_exclusion.key
  })
  commit_message      = "Add data.yaml"
  overwrite_on_create = true
}
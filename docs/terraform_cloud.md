# Terraform Cloud (draft)

This document explains how to use Magic Castle with Terraform Cloud.

## What is Terraform Cloud?

Terraform Cloud is HashiCorp’s managed service that allows to provision
infrastructure using a web browser or a REST API instead of the command-line. 
This also means that the provisioned infrastructure parameters can be modified
by a team and the state is stored in the cloud instead of a local machine.

When provisioning in commercial cloud, Terraform Cloud can also 
provide a cost estimate of the resources.

## 

## Getting started with Terraform Cloud

1. Create a [Terraform Cloud account](https://app.terraform.io/signup/account)
2. [Create an organization](https://app.terraform.io/app/organizations/new), join one or choose one available to you

## Managing a Magic Castle cluster with Terraform Cloud

1. Create a git repository in [GitHub](https://www.github.com/), [GitLab](https://www.gitlab.com/), 
or any of the [version control system provider supported by Terraform Cloud](https://www.terraform.io/docs/cloud/vcs/index.html)
2. In this git repository, add a copy of the Magic Castle example `main.tf` available for the cloud
4. Log in [Terraform Cloud account](https://app.terraform.io/signup/account)
5. Create a new workspace 
6. Choose "Version control workflow"
7. ...

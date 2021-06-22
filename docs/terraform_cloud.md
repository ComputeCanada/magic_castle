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

### Creating the workspace
1. Create a git repository in [GitHub](https://www.github.com/), [GitLab](https://www.gitlab.com/), 
or any of the [version control system provider supported by Terraform Cloud](https://www.terraform.io/docs/cloud/vcs/index.html)
2. In this git repository, add a copy of the Magic Castle example `main.tf`
available for the cloud of your choice
4. Log in [Terraform Cloud account](https://app.terraform.io/signup/account)
5. Create a new workspace
    1. Choose Type: "Version control workflow"
    2. Connect to VCS: choose the version control provider that hosts your repository
    3. Choose the repository that contains your `main.tf`
    4. Configure settings: tweak the name and description to your liking
    5. Click on "Create workspace"

You will be redirected automatically to your new workspace

#### Providing cloud provider credentials to Terraform Cloud

Terraform Cloud will invoke Terraform command-line in a remote virtual environment.
For the CLI to be able to communicate with your cloud provider API, we need to define
environment variables that Terraform will use to authenticate. The next sections
explain which environment variables to define for each cloud provider and how to retrieve
the values of the variable from the provider.

#### AWS

You need to define these environment variables:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY` (sensitive)

The value of these variables can either correspond to the value of access key created
on the [AWS Security Credentials - Access keys](https://console.aws.amazon.com/iam/home?region=ca-central-1#/security_credentials) page, or you can add user dedicated to
Terraform Cloud in [AWS IAM Users](https://console.aws.amazon.com/iam/home?region=ca-central-1#/users),
and use its access key.

#### Azure

You need to define these environment variables:
- `ARM_CLIENT_ID`
- `ARM_CLIENT_SECRET` (sensitive)
- `ARM_SUBSCRIPTION_ID`
- `ARM_TENANT_ID`

Refer to [Terraform Azure Provider - Creating a Service Principal](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/service_principal_client_secret#creating-a-service-principal) to
know how to create a Service Principal and retrieve the values for these environment variables.

#### Google Cloud

You need to define this environment variable:
- `GOOGLE_CLOUD_KEYFILE_JSON` (sensitive)

The value of the variable will be the content of a [Google Cloud service account](https://cloud.google.com/iam/docs/creating-managing-service-accounts)
JSON key file expressed a single line string. Example:
```JSON
{"type": "service_account","project_id": "project-id-1234","private_key_id": "abcd1234",...}
```

You can use [`jq`]() to format the string from the JSON file provided by Google:
```bash
jq . -c project-name-123456-abcdefjg.json
```

#### OpenStack / OVH
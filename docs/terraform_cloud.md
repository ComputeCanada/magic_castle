# Terraform Cloud (draft)

This document explains how to use Magic Castle with Terraform Cloud.

## What is Terraform Cloud?

Terraform Cloud is HashiCorp’s managed service that allows to provision
infrastructure using a web browser or a REST API instead of the command-line.
This also means that the provisioned infrastructure parameters can be modified
by a team and the state is stored in the cloud instead of a local machine.

When provisioning in commercial cloud, Terraform Cloud can also
provide a cost estimate of the resources.

## Getting started with Terraform Cloud

1. Create a [Terraform Cloud account](https://app.terraform.io/signup/account)
2. [Create an organization](https://app.terraform.io/app/organizations/new), join one or choose one available to you

## Managing a Magic Castle cluster with Terraform Cloud

### Creating the workspace
1. Create a git repository in [GitHub](https://www.github.com/), [GitLab](https://www.gitlab.com/),
or any of the [version control system provider supported by Terraform Cloud](https://www.terraform.io/cloud-docs/vcs)
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

### Providing cloud provider credentials to Terraform Cloud

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

You can use [`jq`](https://stedolan.github.io/jq/) to format the string from the JSON
file provided by Google:
```bash
jq . -c project-name-123456-abcdefjg.json
```

#### OpenStack / OVH

You need to define these environment variables:
- `OS_AUTH_URL`
- `OS_PROJECT_ID`
- `OS_REGION_NAME`
- `OS_INTERFACE`
- `OS_IDENTITY_API_VERSION`
- `OS_USER_DOMAIN_NAME`
- `OS_USERNAME`
- `OS_PASSWORD` (sensitive)

Apart from `OS_PASSWORD`, the values for these variables are available in
OpenStack RC file provided for your project.

If you prefer to use [OpenStack application credentials](https://docs.openstack.org/keystone/queens/user/application_credentials.html),
you need to define these variables instead:
- `OS_AUTH_TYPE` 
- `OS_AUTH_URL`
- `OS_IDENTITY_API_VERSION` 
- `OS_REGION_NAME`
- `OS_INTERFACE`
- `OS_APPLICATION_CREDENTIAL_ID`
- `OS_APPLICATION_CREDENTIAL_SECRET`
The values for these variables are available in OpenStack RC file provided
when creating the application credentials.

### Providing DNS provider credentials to Terraform Cloud

Terraform Cloud will invoke Terraform command-line in a remote virtual environment.
For the CLI to be able to communicate with your DNS provider API, we need to define
environment variables that Terraform will use to authenticate. The next sections
explain which environment variables to define for each DNS provider and how to retrieve
the values of the variable from the provider.

#### CloudFlare

You need to define these environment variables:
- `CLOUDFLARE_EMAIL`
- `CLOUDFLARE_API_KEY` (sensitive)

If you prefer using an API token instead of the global API key, you
need to define these environment variables instead:
- `CLOUDFLARE_ZONE_API_TOKEN` (sensitive)
- `CLOUDFLARE_ZONE_DNS_TOKEN` (sensitive)

#### Google Cloud DNS

Refer to [Google Cloud](#google-cloud) section under
Providing cloud provider credentials to Terraform Cloud. Make sure the
Google Cloud service account can modify your DNS zone.

### Managing Magic Castle variables with Terraform Cloud UI

It is possible to use Terraform Cloud web interface to define variable
values in your `main.tf`. For example, you could want to define a guest
password without writing it directly in `main.tf` to avoid displaying
publicly.

To manage a variable with Terraform Cloud:
1. edit your `main.tf`
to define the variables you want to manage. In the following example,
we want to manage the number of nodes and the guest password.

    Add the variables at the beginning of the `main.tf`:
      ```hcl
      variable "nb_nodes" {}
      variable "password" {}
      ```

    Then replace the static value by the variable in our `main.tf`,

    compute node count
      ```hcl
      node = { type = "p2-3gb", tags = ["node"], count = var.nb_nodes }
      ```
    guest password
      ```hcl
      guest_passwd = var.password
      ```
2. Commit and push this changes to your git repository.
3. In Terraform Cloud workspace associated with that repository, go in "Variables.
4. Under "Terraform Variables", click the "Add variable" button and create a variable for each one defined previously in the `main.tf`. Check "Sensitive" if the variable content should not never be shown in the UI or the API.

You may edit the variables at any point of your cluster lifetime.

### Applying changes

To create your cluster, apply changes made to your `main.tf` or the variables,
you will need to queue a plan. When you push to the default branch of the linked
git repository, a plan will be automatically created. You can also create a
plan manually. To do so, click on the "Queue plan manually"
button inside your workspace, then "Queue plan".

Once the plan has been successfully created, you can apply it using the "Runs"
section. Click on the latest queued plan, then on the "Apply plan" button at
the bottom of the plan page.

#### Auto apply

It is possible to apply automatically a successful plan. Go in the "Settings"
section, and under "Apply method" select "Auto apply". Any following successful
plan will then be automatically applied.

## Magic Castle, Terraform Cloud and the CLI

Terraform cloud only allows to apply or destroy the plan as stated in the main.tf,
but sometimes it can be useful to run some other terraform commands that are only
available through the command-line interface, for example `terraform taint`.

It is possible to import the terraform state of a cluster on your local computer
and then use the CLI on it.

1. Log in Terraform cloud:
```sh
terraform login
```

2. Create a folder where the terraform state will be stored:
```sh
mkdir my-cluster-1
```

3. Create a file named `cloud.tf` with the following content in your cluster folder:
```hcl
terraform {
  cloud {
    organization = "REPLACE-BY-YOUR-TF-CLOUD-ORG"
    workspaces {
      name = "REPLACE-BY-THE-NAME-OF-YOUR-WORKSPACE"
    }
  }
}
```
replace the values of `organization` and `name` with the appropriate value
for your cluster.

4. Initialize the folder and retrieve the state:
```sh
terraform init
```

To confirm the workspace has been properly imported locally, you can list
the resources using:
```sh
terraform state list
```

# Enable Magic Castle Elastic Capabilities (experimental)

Magic Castle in combination with Terraform Cloud (TFC) can be configured to give
the Slurm scheduler the ability to create and destroy instances based on the
job queue content.

These are the steps to enable this:
1. [Create a TFC API Token](https://app.terraform.io/app/settings/tokens) and save it somewhere safe.
2. [Create the workspace in TFC](#creating-the-workspace)
  2.1 Make sure the repo is private as it will contain an TFC API token
  2.2 Set the module source to git:
    ```hcl
    source = git::https://github.com/ComputeCanada/magic_castle.git//openstack?ref=elastic
    ```
    Replace `openstack` by your cloud provider.
  2.3 Set 
    ```hcl
    config_version = "elastic"
    ```
3. [Create the environment variables of the cloud provider credentials in TFC](#providing-cloud-provider-credentials-to-terraform-cloud)
4. [Create a variable named `draft_exclusion` in your main.tf and in TFC](#managing-magic-castle-variables-with-terraform-cloud-ui)
  4.1 In the cloud provider module (i.e.: under `module "openstack"` in `main.tf`),
  add the following line:
    ```
    draft_exclusion = var.draft_exclusion
    ```
  4.2 Commit and push the ` main.tf`
5. Add a file named `data.yaml` in your git repo with the following content:
  ```yaml 
  ---
  profile::slurm::controller::tf_cloud_token: <TFC API token>
  profile::slurm::controller::tf_cloud_workspace: <TFC workspace id>
  profile::slurm::controller::tf_cloud_var_name: "draft_exclusion"
  ```
  Complete the file by replacing `<TFC API TOKEN> ` with the token generated at step 1
  and `<TFC workspace id>` (i.e.: `ws-...`) by the id of the workspace created at step 2.
6. In `main.tf`, under `module "openstack"`, add `hieradata = file("data.yaml")`
7. Add `data.yaml` in git, commit all changes and push.
8. In `main.tf`, add instances to `instances` with the tags `draft` and `node`. These are
the nodes that Slurm will able to create and destroy. Commit and push changes in git.
9. Go to your workspace in TFC, click on Actions -> Start a new run -> Plan and apply -> Start run.
10. Compute nodes defined in step 8 can be modified at any point in the cluster lifetime and
more _draft_ compute nodes can be added or removed if needed.

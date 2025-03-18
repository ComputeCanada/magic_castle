# Terraform Cloud

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

You will be redirected automatically to your new workspace.

### Providing cloud provider credentials to Terraform Cloud

Terraform Cloud will invoke Terraform command-line in a remote virtual environment.
For the CLI to be able to communicate with your cloud provider API, we need to define
environment variables that Terraform will use to authenticate. The next sections
explain which environment variables to define for each cloud provider and how to retrieve
the values of the variable from the provider.

If you plan on using these environment variables with multiple workspaces, it is recommended
to [create a credential variable set](https://learn.hashicorp.com/tutorials/terraform/cloud-multiple-variable-sets?in=terraform/cloud#create-a-credentials-variable-set) in Terraform Cloud.

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
you need to define at least these variables:
- `OS_AUTH_TYPE` 
- `OS_AUTH_URL`
- `OS_APPLICATION_CREDENTIAL_ID`
- `OS_APPLICATION_CREDENTIAL_SECRET`

and potentially these too:
- `OS_IDENTITY_API_VERSION` 
- `OS_REGION_NAME`
- `OS_INTERFACE`

The values for these variables are available in OpenStack RC file provided
when creating the application credentials.

### Providing DNS provider credentials to Terraform Cloud

Terraform Cloud will invoke Terraform command-line in a remote virtual environment.
For the CLI to be able to communicate with your DNS provider API, we need to define
environment variables that Terraform will use to authenticate. The next sections
explain which environment variables to define for each DNS provider and how to retrieve
the values of the variable from the provider.

#### CloudFlare

Refer to DNS - [CloudFlare](README.md#61-cloudflare) section of Magic Castle main documentation
to determine which environment variables needs to be set.

#### Google Cloud DNS

Refer to DNS - [Google Cloud](README.md#62-google-cloud) section of Magic Castle main documentation
to determine which environment variables needs to be set.

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
available through the command-line interface.

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

## Enable Magic Castle Autoscaling

Magic Castle in combination with Terraform Cloud (TFE) can be configured to give
Slurm the ability to create and destroy instances based on the
job queue content.

To enable this feature:
1. [Create a TFE API Token](https://app.terraform.io/app/settings/tokens) and save it somewhere safe.

    1.1. If you subscribe to Terraform Cloud Team & Governance plan, you can generate
    a [Team API Token](https://www.terraform.io/cloud-docs/users-teams-organizations/api-tokens#team-api-tokens).
    The team associated with this token requires no access to organization and can be secret.
    It does not have to include any member. Team API token is preferable as its permissions can be
    restricted to the minimum required for autoscale purpose.

2. [Create a workspace in TFE](#creating-the-workspace)

    2.1. Make sure the repo is private as it will contain the API token.

    2.2. If you generated a Team API Token in 1, provide access to the workspace to the team:

      1. Workspace Settings -> Team Access -> Add team and permissions
      2. Select the team
      3. Click on "Customize permissions for this team"
      4. Under "Runs" select "Apply"
      5. Under "Variables" select "Read and write"
      6. Leave the rest as is and click on "Assign custom permissions"

3. [Create the environment variables of the cloud provider credentials in TFE](#providing-cloud-provider-credentials-to-terraform-cloud)
4. [Create a variable named `pool` in TFE](#managing-magic-castle-variables-with-terraform-cloud-ui). Set value to `[]` and check **HCL**.
5. Add a file named `data.yaml` in your git repo with the following content:
    ```yaml 
    ---
    profile::slurm::controller::tfe_token: <TFE API token>
    profile::slurm::controller::tfe_workspace: <TFE workspace id>
    ```
    Complete the file by replacing `<TFE API TOKEN> ` with the token generated at step 1
    and `<TFE workspace id>` (i.e.: `ws-...`) by the id of the workspace created at step 2.
    It is recommended to encrypt the TFE API token before committing `data.yaml` in git. Refer
    to section [4.15 of README.md](./README.md#415-eyaml_key-optional) to
    know how to encrypt the token.
6. Add `data.yaml` in git and push.
7. Modify `main.tf`:

      1. If not already present, add the following definition of the pool variable at the beginning of your `main.tf`.

      ```hcl
      variable "pool" { description = "Slurm pool of compute nodes" }
      ```

      2. Add instances to `instances` with the tags `pool` and `node`. These are
      the nodes that Slurm will able to create and destroy.
      3. If not already present, add the following line after the instances definition to pass the list of compute nodes from Terraform cloud workspace variable to the provider module:

      ```hcl
      pool = var.pool
      ```

      4. On the right-hand-side of `public_keys = `, replace `[file("~/.ssh/id_rsa.pub")]`
      by a list of SSH public keys that will have admin access to the cluster.
      5. After the line `public_keys = ...`, add `hieradata = file("data.yaml")`.
      6. Stage changes, commit and push to git repo.

9. Go to your workspace in TFE, click on Actions -> Start a new run -> Plan and apply -> Start run.
Then, click on "Confirm & Apply" and "Confirm Plan".
10. Compute nodes defined in step 8 can be modified at any point in the cluster lifetime and
more _pool_ compute nodes can be added or removed if needed.

### Considerations for autoscaling
To reduce the time required for compute nodes to become available in Slurm, consider
[creating a compute node image](./README.md#1012-create-a-compute-node-image).

JupyterHub will time out by default after 300 seconds if a node is not spawned yet. Since it may
take longer than this to spawn a node, even with an image created, consider increasing the timeout
by adding the following to your YAML configuration file: 
```
jupyterhub::jupyterhub_config_hash:
  SlurmFormSpawner:
    start_timeout: 900
```

### Troubleshoot autoscaling with Terraform Cloud

If after enabling autoscaling with Terraform Cloud for your Magic Castle cluster,
the number of nodes does not increase when submitting jobs, verify the following
points:

1. Go to the Terraform Cloud workspace webpage, and look for errors in the runs.
If the runs were only triggered by changes to the git repo, it means scaling signals
from the cluster do not reach the Terraform cloud workspace or no signals were sent at all.
2. Make sure the Terraform Cloud workspace id matches with the value of
`profile::slurm::controller::tfe_workspace` in `data.yaml`.
3. Execute `squeue` on the cluster, and verify the reasons why jobs are still in the queue.
If under the column `(Reason)`, there is the keyword `ReqNodeNotAvail`, it implies
Slurm tried to boot the listed nodes, but they would not show up before the timeout,
therefore Slurm marked them as down. It can happen if your cloud provider is slow to build
the instances, or following a configuration problem like in 2. When Slurm marks a node as
down, a trace is left in slurmctld's log - using zgrep on the slurm controller node (typically `mgmt1`):
    ```bash
    sudo zgrep "marking down" /var/log/slurm/slurmctld.log*
    ```
    To tell Slurm these nodes are available again, enter the following command:
    ```bash
    sudo /opt/software/slurm/bin/scontrol update nodename=node[Y-Z] state=IDLE
    ```
    Replace `node[Y-Z]` by the hostname range listed next to `ReqNodeNotAvail` in `squeue`.
4. Under `mgmt1:/var/log/slurm`, look for errors in the file `slurm_resume.log`.

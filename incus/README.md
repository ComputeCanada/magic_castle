# Magic Castle for Incus

## What is Incus

From [linuxcontainers.org](https://linuxcontainers.org/incus/#what-is-incus):
> Incus is a next-generation system container, application container, and virtual machine manager.
>
> It provides a user experience similar to that of a public cloud. With it, you can easily mix and match both containers and virtual machines, sharing the same underlying storage and network.


## How to instal Incus

To install Incus on your personal compute or in a virtual machine,
follow the instructions: [Install and initialize Incus](https://linuxcontainers.org/incus/docs/main/tutorial/first_steps/#install-and-initialize-incus)

## How to create a Magic Castle cluster with Incus

1. [Install terraform](https://developer.hashicorp.com/terraform/install) on the same machine running Incus.
2. Grab the incus example [main.tf](./main.tf)
3. Set the incus terraform provider environment variable : `export INCUS_SOCKET=/var/run/incus/unix.socket`
4. Initialize terraform: `terraform init`
5. Apply: `terraform apply`
6. Note the project id from the terraform output.
7. Connect to an instance, replace `<project>` by incus project id: `incus --project <project> exec mgmt1 -- /bin/bash`.

## What features are not currently supported?

When deploying Magic Castle with Incus, the following features are currently not supported:
- Virtual machine instance type
- Volumes
- GPU
- Firewall / network ACLs
- SELinux
- NFS Automount


## Autoscaling with Terraform Cloud

It is possible to enable the cluster autoscaling as described in
[https://github.com/ComputeCanada/magic_castle/blob/main/docs/terraform_cloud.md](Magic Castle Terraform Cloud documentation).

Since Incus is a local provider, a local terraform agent is required.
To setup a Terraform agent, [follow the instructions](https://developer.hashicorp.com/terraform/tutorials/cloud/cloud-agents).
The Terraform agent has to run on the same machine as the incus server. In the Terraform cloud workspace of the cluster, make
sure to define the environment variable `INCUS_SOCKET=/var/run/incus/unix.socket`. This will allow the Terraform agent to
communicate with Incus.


# Magic Castle for Incus example

## What is Incus 

From [linuxcontainers.org](https://linuxcontainers.org/incus/#what-is-incus):
> Incus is a next-generation system container, application container, and virtual machine manager.
>
> It provides a user experience similar to that of a public cloud. With it, you can easily mix and match both containers and virtual machines, sharing the same underlying storage and network.


## How to instal Incus

To install Incus on your personal compute or in a virtual machine,
follow the instructions: [Install and initialize Incus](https://linuxcontainers.org/incus/docs/main/tutorial/first_steps/#install-and-initialize-incus)

Magic Castle currently has issue when instances are being assigned an IPV6 id.
Therefore when initializing incus, to the question
```
What IPv6 address should be used? (CIDR subnet notation, “auto” or “none”) [default=auto]
```
answer: `none`.

## How to create a Magic Castle cluster with Incus

1. [Install terraform](https://developer.hashicorp.com/terraform/install) on the same machine running Incus.
2. Grab the incus example [main.tf](./main.tf)
3. Set the incus terraform provider environment variable : `export INCUS_SOCKET=/var/run/incus/unix.socket`
4. Initialize terraform: `terraform init`
5. Apply: `terraform apply`
6. Connect to an instance: `incus exec mgmt1 -- /bin/bash`

## What features are not currently included?

When running Magic Castle instances are containers, the following currently does not work:
- SELinux
- NFS Automount

In general (virtual machines and containers):
- public instances are not directly reachable from the Internet after creation,
you need to configure the incus host to redirect traffic to the public instances.

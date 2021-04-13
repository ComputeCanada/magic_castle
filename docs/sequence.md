# Magic Castle Sequence Diagrams

The following sequence diagrams illustrate the inner working of Magic Castle
once `terraform apply` is called. Some details were left out of the diagrams,
but every diagram is followed by references to the code files that were used
to build it.

## 1. Cluster creation

![Cluster Creation Sequence](./diagrams/cluster_creation_sequence.svg)

### Notes

1. `puppet-magic_castle.git` does not have to refer to `ComputeCanada/puppet-magic_castle.git` repo.
Users can use their own fork. See the [developer documentation](/docs/developers.md) for more details.

### References

- [`magic_castle:/common/design/main.tf`](/common/design/main.tf)
- [`magic_castle:/openstack/infrastructure.tf`](/openstack/network.tf)
- [`magic_castle:/common/instance_config/main.tf`](/common/instance_config/main.tf)
- [`magic_castle:/openstack/infrastructure.tf`](/openstack/infrastructure.tf)
- [`magic_castle:/common/cluster_config/main.tf`](/common/cluster_config/main.tf)
- [`magic_castle:/dns/cloudflare/dns.tf`](/dns/cloudflare/dns.tf)
- [`magic_castle:/dns/acme/acme.tf`](/dns/acme/acme.tf)

## 2. Configuration with cloud-init

![Configuration with cloud-init sequence](./diagrams/cluster_configuration_cloud-init_sequence.svg)

### Notes

1. `config_git_url repo` does not have to refer to `ComputeCanada/puppet-magic_castle.git` repo.
Users can use their own fork. See the [developer documentation](/docs/developers.md) for more details.
2. While the diagram represents each step as completed sequentially, each node provisioning
is independent. The only step that requires synchronisation between nodes and the management node
is the puppet certificate generation.

### References

- [`magic_castle:/common/instance_config/puppet.yaml`](/common/instance_config/puppet.yaml)


## 3. Configuration with Puppet

![Provisioning with Puppet](./diagrams/cluster_provisioning_puppet_sequence.svg)

### References

- [`puppet-magic_castle:/manifests/site.pp`](https://github.com/ComputeCanada/puppet-magic_castle/blob/main/manifests/site.pp)
- [`puppet-magic_castle:/profile/manifests/base.pp`](https://github.com/ComputeCanada/puppet-magic_castle/blob/main/site/profile/manifests/base.pp)
- [`puppet-magic_castle:/profile/manifests/consul.pp`](https://github.com/ComputeCanada/puppet-magic_castle/blob/main/site/profile/manifests/consul.pp)
- [`puppet-magic_castle:/profile/manifests/freeipa.pp`](https://github.com/ComputeCanada/puppet-magic_castle/blob/main/site/profile/manifests/freeipa.pp)

## 4. Configuration with Consul and Consul Template

![Provisioning with Consul](./diagrams/cluster_provisioning_consul_sequence.svg)

### References

- [`puppet-magic_castle:/profile/manifests/consul.pp`](https://github.com/ComputeCanada/puppet-magic_castle/blob/main/site/profile/manifests/consul.pp)
- [`puppet-magic_castle:/profile/manifests/cvmfs.pp`](https://github.com/ComputeCanada/puppet-magic_castle/blob/main/site/profile/manifests/cvmfs.pp)
- [`puppet-magic_castle:/profile/manifests/slurm.pp`](https://github.com/ComputeCanada/puppet-magic_castle/blob/main/site/profile/manifests/slurm.pp)

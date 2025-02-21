# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [14.2.1] 2025-02-21

No changes to infrastructure code.

Refer to [puppet-magic_castle changelog](https://github.com/ComputeCanada/puppet-magic_castle/blob/main/CHANGELOG.md)

## [14.2.0] 2025-02-20

### Added

- Added documentation for FreeIPA configuration (PR #344)

### Changed

- Generalized definition of instance's specs (PR #341)
- Made tf user a system user (PR #343)
- Splited sshd config so that Match directives are in their own files (PR #345)

## [14.1.3] 2025-01-29

### Changed

- Set an upper bound on CloudFlare provider version.

## [14.1.2] 2024-11-10

### Added

- Added rsync to the list of essential packages installed by cloud-init (PR #336)

### Changed

- Fix how security group are associated with instance tags (PR #336)

## [14.1.1] 2024-11-19

### Changed

- Added `admin_ssh_key` to the `ignore_changes` list in Azure (PR #335)

## [14.1.0] 2024-11-17

### Changed

- Upgraded AWS provider version to 5.76.0
- Replaced AWS legacy `aws_instance_spot_request` by `aws_instance`'s `instance_market_options`.
- Fixed Azure public ips `sku` to `Standard` and `allocation_method` to `static`.

## [14.0.0] 2024-11-12

### Added
- Added GPU sharding (PR #289)
- Added ability to define a hieradata per prefix (PR #291)
- Added user tf in puppet.yaml (#316)

### Changed

- Refactored SSHFP record generation removing hardcoded algorithm names (PR #301)
- Fixed owner of puppet data when there is no bastion (PR #302)
- Refactored variable Puppetfile to include it in the remove-exec provisioner (PR #306)
- Moved cloud facts in user-data (PR #307)
- Hostkeys are now chomped (PR #308)
- Dropped support for CentOS 7 (PR #309)
- Moved volumes in instance specs (PR #275)
- Fixed #313 "Terraform can't create more than one instance with the "login" tag in Azure" (PR #314)
- Updated cloudflare record to support >=v4.39.0 (PR #318)
- Fixed terraform lock file in release (PR #320)
- Bumped puppet and gem versions (PR #322)
- Moved to Rocky / Alma Linux 9 in examples (PR #323)
- Empty string var.hieradata is now allowed
- Increased AWS instance volume size to 20gb
- Fixed /etc permissions issue with Rocky 9.4
- Defined a value for sku in azurerm_public_ip (PR #332)

### Removed

- Removed generation of private_key.pkcs7.pem from puppet.yaml (Issue #260, PR #303)

## [13.5.0] 2024-04-11

### Added

- Support for NVIDIA MIG (PR #288)
- Rendering of documentation with MkDoc (PR #290)
- Material for MkDocs to render documentation

### Removed

- Removed install of EFA driver from cloud-init (PR #293)

## [13.4.0] 2024-04-09

### Added

- Added Yaml validation on hieradata (PR #284)
- Added mount of ephemeral volume to cloud-init (puppet.yaml) (PR #295)

### Changed

- Improve var.software_stack flexibility and documentation (PR #281)
- Bumped puppet-agent to 7.28.0
- Fixed openstack_compute_floatingip_associate_v2 deprecation (PR #285)
- Simplify Azure utils vmsizes.py by relying on az CLI tool (PR #296)
- Updated Azure vmsizes.json (PR #297)


## [13.3.2] 2024-02-19

No changes to infrastructure code.

Refer to [puppet-magic_castle changelog](https://github.com/ComputeCanada/puppet-magic_castle/blob/main/CHANGELOG.md)

## [13.3.1] 2024-01-17

No changes to infrastructure code.

Refer to [puppet-magic_castle changelog](https://github.com/ComputeCanada/puppet-magic_castle/blob/main/CHANGELOG.md)

## [13.3.0] 2024-01-15

No changes to infrastructure code.

Refer to [puppet-magic_castle changelog](https://github.com/ComputeCanada/puppet-magic_castle/blob/main/CHANGELOG.md)

## [13.2.1] 2024-01-12

### Changed
- Bumped puppet-agent version to 7.27.0 and puppet-server version to 7.14.0

## [13.2.0] 2024-01-09

### Added

- Added validation on `cluster_name`, `domain` and instance's `prefix` (#257)
- Added documentation on SSHFP and DNSSEC activation

### Changed

- Replaced `instances` by `instances_to_build` in `module.design` to allow pool node to have volumes (#272)
- Fixed version of faraday and faraday-net_http in cloud-init (#277)

Refer to [puppet-magic_castle changelog](https://github.com/ComputeCanada/puppet-magic_castle/blob/main/CHANGELOG.md)
for details on change to the Puppet environment.

## [13.1.0] - 2023-10-27

### Changed

- [cloudflare] SSHFP fingerprints are now uppercase.

Refer to [puppet-magic_castle changelog](https://github.com/ComputeCanada/puppet-magic_castle/blob/main/CHANGELOG.md)
for details on change to the Puppet environment.

## [13.0.0] - 2023-10-13

#### Added

- Added `skip_upgrade` variable to main module
- Added `puppetfile` variable to main module
- Added variable vhosts to cloudflare and gcloud dns
- [AWS] Added ipv6 support in AWS security groups
- Added wait loop for terraform_data.yaml in puppet.yaml
- [GCP] Added t2a machine-type to GCP machine_type.py
- Added documentation section on volume expansion

### Changed

- [cloud-init] FQDN is now part of instances' hostname in cloud-init
- [openstack] Replaced deprecated compute_secgroup by networking_secgroup
- Firewalls rules are now defined based on tags instead global static rules
- Port 22 for SSH connection is now open only for `login` tagged instances of all instances with public ip address
- Replaced `null_resource` by `terraform_data`
- Bumped terraform minimum required version to 1.4.0
- Issuing wildcard certificate is now optional
- Replaced librarian-puppet by r10k

### Removed

- Removed email variable in examples' dns module

Refer to [puppet-magic_castle changelog](https://github.com/ComputeCanada/puppet-magic_castle/blob/main/CHANGELOG.md)
for details on change to the Puppet environment.

## [12.6.1] to [12.6.8]

No changes to infrastructure code.

Refer to [puppet-magic_castle changelog](https://github.com/ComputeCanada/puppet-magic_castle/blob/main/CHANGELOG.md)

## [12.6.0] - 2023-06-29

#### Added

- Added another source of GPU spec to OpenStack. Allow GPU support with OVH.
- Added support to have more than one puppet server.
- Added writing of csr_attributes.yaml on all instances, including puppet servers.
- Added writing of terraform_data.yaml and terraform_facts.yaml with cloud-init when there are no `public` instances.
- Added `puppetservers` variable definition to `module.common.configuration`.

### Changed
- Set `manage_etc_hosts` in cloud-init explicitly to false.
- Fixed jq path to retrieve consul ACL agent token when launching the puppet event with consul.
- Simplified provision remote-exec command by taking advantage puppet id and gid are reserved to "52".
- Moved definition of autosign.log in cloud-init write_files
- Changed autosign validation order to just include password_list
- Changed puppetserver install command to install it with Java 11 in one line.
- Fixed puppet.conf reference to master and replace it by server.
- Changed cloud-init to make sure only the first puppetserver is the certificate authority (CA)
- Changed the local variable named `all_instances` to `inventory`.
- Moved `to_build_instances` in `module.common.design`.
- Renamed `module.common.instance_config` to `module.common.configuration`.
- Renamed `module.common.cluster_config` to `module.common.provision`.

### Removed

- Removed keypair resource from OpenStack. Keypairs are written directly in cloud-init YAML.
- Removed puppetserver id trigger for remote provisioner of terraform_data and terraform_facts
- Removed creation of /var/autosign from cloud-init
- Removed `puppetservers` variable from all network.tf

## [12.5.0] - 2023-06-06

### Changed

- Updated puppet-server and puppet-agent to Puppet 7.
- Set `force_delete = true` in OpenStack to avoid soft deletion of instances.

## [12.4.0] 2023-05-04

#### Added
- Added documentation on troubleshooting autoscaling with Terraform Cloud.
- Added ability to use partially matching regular expression to define image name in OpenStack.

## [12.3.0] 2023-02-22

### Added
- Added the hostname prefix to instance definition in `terraform_data.yaml`.

Refer to [puppet-magic_castle changelog](https://github.com/ComputeCanada/puppet-magic_castle/blob/main/CHANGELOG.md)
for details on change to the Puppet environment.

## [12.2.0] 2023-02-02

### Added
- Added validation on the count of _proxy_ tagged instance (max 1)
- Added validation on the count of _login_ tagged instances (max 1 prefix)
- Added `explore` vhost in dns

### Changed
- Fixed runcmd condition for dnf.conf


## [12.1.0] 2023-01-17

### Added
- [cloud-init] Added generation of a PKCS7 encryption key for the end user to encrypt hieradata secrets
- [cloud-init] Added generation of a PCKS7 encryption key for the bootstrap script to encrypt hieradata secrets
- Added possibility to encrypt guest password
- Added documentation on encryption of secrets with Puppet and hieradata
- Added documentation on hostname composition rules

### Removed
- Removed `munge_key` and `consul_token` generation from Terraform
- Removed `freeipa_admin` generation from Terraform

## [12.0.0] 2023-01-16

### Added
- [cloud-init] Enabled fastest mirror selection in dnf config
- [cloud-init] Added logic to handle admin account being already created at first boot
- Added a timestamp as payload to consul puppet event to avoid rebooting puppet for past events
- Added variable `var.pool` and "pool" tag to enable Slurm autoscaling with Terraform Cloud (PR #216)
- Added a script to build a static JSON file containing Azure instance types specification (#cpu, ram, #gpus)
- Added a script to compute GCP instance specifications based on the instance type name
- Added documentation on how to use Magic Castle with Terraform Cloud to enable Slurm autoscaling

### Changed

- puppet-magic_castle now has its own [changelog](https://github.com/ComputeCanada/puppet-magic_castle/blob/main/CHANGELOG.md)
- Updated Terraform minimum version to 1.2.1 from 1.1.0
- [cloud-init] Excluded puppet from yum upgrade
- [cloud-init] Added a check to skip upgrade and puppet install if puppet-magic_castle has ran at least once.
- [cloud-init] Excluded iptables from firewalld uninstall
- Changed instance types in Google Cloud example
- Fixed AWS spot instances data structure composition

### Removed

- [cloud-init] Removed `packages` section

## [11.9.5] 2022-08-09

### Changed
- Fixed RPM source for CVMFS yum repo (issue [#206](https://github.com/ComputeCanada/puppet-magic_castle/issues/206))

## [11.9.4] 2022-07-08

### Changed
- Fix azurerm_network_interface private_ip_address_allocation value (dynamic -> Dynamic)

## [11.9.3] 2022-05-09

### Changed
- [puppet] Bumped puppet-jupyterhub to v4.3.1 to enable code-server and openrefine launchers in JupyterLab.

## [11.9.2] 2022-05-04

### Changed
- Set AWS Terraform provider version to v4.10.0 (issue #212)

## [11.9.1] 2022-05-02

### Changed
- Replaced direct call to keystone.py and key2fp.py by shell wrapped script call.
This fixes an issue with Terraform Cloud or system that do not provide `python3`.
The wrapper script test the existence for different name for python cli and choose
start the script with the first one available.
- Made key2fp.py compatible with Python 2 to ensure compatibility with TF Cloud.

## [11.9.0] 2022-04-22

### Added

- Added support for OS_CLIENT_CONFIG_FILE in keystone.py
- Added support for ed25519 hostkeys and SSH keys (issue #210)
- Add acme_key_pem optional variable to DNS modules (issue #205)
- [puppet] sssd can now be configured with additional LDAP domains (issue [#179](https://github.com/ComputeCanada/puppet-magic_castle/issues/179))
- [puppet] Added class to support cephfs mount

### Changed

- Replaced python by python3 in external data source (issue #208)
- [puppet] SELinux mode is now configurable through hieradata.
- [puppet] SELinux default mode is now `permissive` instead of `enforcing`.
- [puppet] Moved munge_socket selinux::module in slurm::base (issue [#178](https://github.com/ComputeCanada/puppet-magic_castle/issues/178))
- [puppet] Set MemSpecLimit in slurm.conf and allow configuration using hieradata (issue [#181](https://github.com/ComputeCanada/puppet-magic_castle/issues/181))
- [puppet] Hardened SSHD config for CentOS 8 (issue [#182](https://github.com/ComputeCanada/puppet-magic_castle/issues/182))
- [puppet] Fixed issue with cat of file inside interactive Slurm jobs (issue [#183](https://github.com/ComputeCanada/puppet-magic_castle/issues/183))
 - [puppet] NFS devices can now be an empty string (issue [#185](https://github.com/ComputeCanada/puppet-magic_castle/issues/185))
- [puppet] Fixed notebook and terminals link in slurmformspawner hieradata (issue [#189](https://github.com/ComputeCanada/puppet-magic_castle/issues/189))
- [puppet] Replaced workshop class by an account parameter that adds folders to /etc/skel based on archives fetched from URL provided in hieradata of profile::account (issue [#191](https://github.com/ComputeCanada/puppet-magic_castle/issues/191))
- [puppet] Replaced Apache reverse proxy by Caddy (issue [#195](https://github.com/ComputeCanada/puppet-magic_castle/issues/195))
- [puppet] Dropped support for Globus v4 and replaced most of profile::globus code by `treydock/globus` module to add support for Globus v5.4.
- [puppet] Local users are now required to be created for cloud-init suoders to be removed

### Removed
- [DNS] Removed the `dtn` entry for the Globus endpoint.
- [puppet] Removed class `profile::workshop`

## [11.8] 2022-02-16

### Added
- Added `image` optional instance attribute (PR #203)
- [Azure] Added the optional `plan` variable to allow usage of images that require plan information (issue #201)
- [puppet] Added missing rpm for nvidia gpu passthrough setup in CentOS 8 (issue [#159](https://github.com/ComputeCanada/puppet-magic_castle/issues/159))
- [puppet] Added confinement of users in Slurm's jobs when using Slurm >= 21.08 (PR [#164](https://github.com/ComputeCanada/puppet-magic_castle/issues/164))
- [puppet] Added configuration of NetworkManager DNS config for ipa-server (issue [#169](https://github.com/ComputeCanada/puppet-magic_castle/issues/169))
- [puppet] Added ability to create local users with hieradata (PR [#174](https://github.com/ComputeCanada/puppet-magic_castle/issues/174))
- [puppet] Added ability to create LDAP users with hieradata (PR [#175](https://github.com/ComputeCanada/puppet-magic_castle/issues/175))
- [puppet] Added ssh public keys to ipa_create_user.py

### Changed
- Updated Terraform minimum version to 1.1.0 from 0.14.2
- Updated image in all examples to use either Rocky or AlmaLinux 8
- [AWS] Ensure AWS spot instances can be persistent (PR #193)
- [Azure] Use spot specific values only when using spot instances (Issue #199)
- [puppet] Updated Compute Canada software stack to version 2020 for CentOS 7 and 8
- [puppet] Fixed regex for EESSI repositories (issue [#161](https://github.com/ComputeCanada/puppet-magic_castle/issues/161))
- [puppet] Fixed compatibility with Slurm 21.08 (issue [#162](https://github.com/ComputeCanada/puppet-magic_castle/issues/162))
- [puppet] Fixed sss cache invalidation (issue [#165](https://github.com/ComputeCanada/puppet-magic_castle/issues/165))
- [puppet] Put lmod_default_modules in computecanada.yaml (PR [#172](https://github.com/ComputeCanada/puppet-magic_castle/issues/172))
- [puppet] Changed default slurm version to 21.08
- [puppet] Refactored ipa_create_user.py arguments (PR [#173](https://github.com/ComputeCanada/puppet-magic_castle/issues/173))
- [puppet] Updated puppet-jupyterhub version to v4.1.0 (PR [#176](https://github.com/ComputeCanada/puppet-magic_castle/issues/176))

### Removed
- [puppet] Remove dhclient removal in centos 8 (PR [#170](https://github.com/ComputeCanada/puppet-magic_castle/issues/170))

## [11.7] 2021-11-02

### Changed
- [OpenStack] Replaced `var.os_int_subnet` by `var.subnet_id` as subnet can have the same name across networks.
- [puppet] Update puppet module `consul_template` to 2.3.3.

### Removed
- [OpenStack] Removed `var.os_int_network`.

## [11.6] 2021-10-12

### Changed
- [puppet] Replaced resolv.conf configuration with `file_line` by config of NetworkManager.
- [puppet] Updated puppet-mysql version to fix encoding issue.
- [puppet] Defined the seltype of ipa-rewrite.conf.

## [11.5] 2021-10-06

### Changed
- [puppet] Fixed Slurm email sending (issue #144)
- [puppet] Fixed freeipa server idstart value (PR #146)
- [puppet] Deactivated expiration date of admin password (issue #147, PR #149)
- [puppet] Fixed location of scratch symlink in mkhome.sh (issue #148, PR #150)

## [11.4] 2021-09-22

### Added
- Added Elastic Fabric Adapter support for AWS
- Generalized NFS volumes exportation to support more than home, project and scratch
- [puppet] Added epel as requirement for gpu passthrough packages
- [puppet] Added Slurm 21.08 to the list of versions that can be installed

### Changed
- Fixed puppet launch event in `cluster_config`
- Updated `cloudflare_record` usage to support CloudFlare 3.0 Terraform module.
- Users have to use a valid project name when submitting jobs.
- `centos` can no longer submitted jobs.
- [puppet] Disabled resource limit propagation in Slurm
- [puppet] Configured ipa admin account passwd to never expire

## [11.3] 2021-07-22

### Added
- Added documentation on how to use Terraform Cloud
- Added a trigger when uploading SSL certificates
- Added documentation on how to regenerate SSL certificates
- Added support for Rocky Linux and AlmaLinux
- [puppet] Added X11 forwarding enabling in Slurm config


### Changed
- Improved various sections of the documentation
- Updated puppet-agent to 6.16.0
- Updated puppet-server to 6.23.0
- [puppet] Updated puppet-jupyterhub to v3.8.8
- [cloud-init] Replaced deprecated ssh config algorithm selection parameter
- [puppet] Replaced network-scripts by NetworkManager
- [puppet] Fixed fail2ban config when not using CentOS
- [puppet] Fixed powertools enabling when not using CentOS

### Removed
- [puppet] Removed dhclient package when os major release is 8

## [11.2] 2021-06-02

### Added
- Added a Consul event that can trigger the reload of Puppet agent configuration
- Added the triggering of the consul puppet event when hieradata or terraform_data.yaml
is changed after a `terraform apply`.
- [puppet] Added the user `sudoer_username` and its authorized_keys to profile::base.

### Changed
- SSH public keys can now be added to `public_keys` after the cluster is built,
without rebuilding all instances.
- [cloud-init] Changes to cloud-init file are ignored once the instances are created
- [cloud-init] Moved installation of puppet-agent rpm before puppet-server
- [cloud-init] Moved bootstrapping of consul server in `puppet-magic_castle`'s bootstrap.sh
- [puppet] Bumped puppet-jupyterhub to v3.8.6
- [puppet] Fixed workshop class for guest accounts

### Removed
- [puppet] Globus Connect Server V5 class


## [11.1] 2021-05-18

### Added
- Support for spot instances in AWS, Azure and Google Cloud
- GitHub actions to lint documentation
- Advanced example demonstrating how to create an ELK cluster
- Advanced example demonstrating how to create a kubernetes cluster
- Advanced example demonstrating how to create an Apache Spark cluster
- [cloud-init] Check for the presence of `bootstrap.sh` in the puppet environment

### Changed
- Fixed issue with Google Cloud DNS referring to CloudFlare (PR #167 @consideratio)
- Fixed documentation (PR #169 @consideratio)
- Fixed var.volumes validation - allowing the variable to be an empty map
- Fixed terraform_facts.yaml format for cloud provider and region
- Reintroduced nouveau driver blacklisting in cloud-init
- Improved provider specific READMEs
- Reverted flavors and image in openstack example to Arbutus instead of Beluga Cloud
- [AWS] Updated AMI value in the example
- [puppet] Fixed init of /etc/cvmfs/default.local with consul-template

## [11.0] 2021-04-19

### Added
- Add `volumes` variable structure to define volumes that will be attached to instances with matching tags.
- Reference design documentation
- Added straightforward password replacement procedur (PR #152 @plstonge)
- Added advice on user management when not creating users (PR #153 @ocaisa)
- Added freeipa admin username and password to the output (PR #154 @ocaisa)
- Added a basic puppet cluster example
- Added a basic lustre cluster setup example

### Changed
- Changed `instances` variable structure to add tags
- Updated developer documentation
- Updated main documentation
- Merged puppet agent and puppet server cloud-init YAML file in a single file
- Combined some of the DNS module inputs to in a single variable
- Defined a default value for `nb_users` (0)
- Changed format of `terraform_data.yaml` to no longer depends on puppet-magic_castle
- Moved resources related to networking in `network.tf` for each cloud provider
- Normalized most resource names across providers
- Changed `os_floating_ips` input type from list to map
- [puppet] Updated EESSI CVMFS config version
- [puppet] Changed how devices for NFS server are identified using facts instead of glob
- [puppet] Bumped puppet-jupyterhub version to v3.8.2
- [puppet] Fixed gpu profile for pci passthrough providers
- [puppet] Replaced site.pp roles based on hostnames by roles based on tags

### Removed
- Removed fetching of `terraform_data.yaml.tmpl` from `config_git_url` repo
- Removed `storage` variable, replaced by `volumes`.
- Removed Azure variable `managed_disk_type`
- Removed common variable `root_disk_size`

## [10.2] 2021-03-10

### Added
- Added GitHub actions workflows for validation and release
- [puppet] Added GitHub actions workflows for validation

### Changed
- [puppet] Fixed the logic in mkproject.sh to avoid empty GID

### Removed
- Removed Travis CI yaml
- [puppet] Removed Travis CI yaml

## [10.1] 2021-03-08

### Added
- [puppet] Added log rotation rules for Slurm daemons
- [puppet] Added configuration of Prometheus retention time and storage

### Changed
- Updated documentation
- [puppet] Changed /localscratch SELinux label from `default_t` to `tmp_t`
- [puppet] Bumped puppet-jupyterhub version to 3.7.3
- [puppet] Refactored mkproject daemon to allow removal of users from Slurm account when
removing them from the associated POSIX group in FreeIPA.

### Removed
- Removed possibility of having underscores in `cluster_name`

## [10.0] 2021-02-24

### Added
- Added `config_git_url` and `config_version` to all examples
- Added a DNS module that produce a text file that can be imported in DNS zone
for providers that are currently not supported by MC.
- [puppet] Added cloud provider and region to puppet facts
- [puppet] Added failmode option to Duo
- [puppet] Added fallback to nvidia-smi for GPU driver version

### Changed
- Bumped Terraform minimum version to 0.14.5
- Fixed Acme provider name (issue #)
- Renamed `puppetenv_git` to `config_git_url`
- Renamed `puppetenv_rev` to `config_version`
- Made `config_git_url` and `config_version` mandatory.
- Improved documentation
- [puppet] Reverted "Remove export of security labels in nfs"
- [puppet] Fixed label issues with home, project and scratch root folder ([puppet-magic_castle issue #96](https://github.com/ComputeCanada/puppet-magic_castle/issues/96))
- [puppet] Generalized VGPU driver installation to support other clouds
- [puppet] Changed default Slurm version from 19.05 to 20.11
- [puppet] Fix guest account username zero-padding when nb_accounts < 10

## [9.3] 2021-01-26

### Added
- Added configuration of NFS server running versions with nfs.conf

### Changed
- Excluded slurm from EPEL yum repo

## [9.2] 2021-01-13

### Added
- Added support for multiple software stacks including Compute Canada and EESSI (PR #124)
- [azure] Added support for configuration of image using image_id
- [puppet] Added automatic Slurm node weight computation through consul2slurm
- [puppet] Added a wrapper for ipa-client-install to make nsupdate failure fatal ([puppet-magic_castle issue #79](https://github.com/ComputeCanada/puppet-magic_castle/issues/79))
- [puppet] Added definition of bind_addr parameter in consul config ([puppet-magic_castle issue #83](https://github.com/ComputeCanada/puppet-magic_castle/issues/83))

### Changed
- Fixed `cluster_name` validation and documentation
- Simplified version locking in release.sh
- [puppet] Changed `'ensure'` of package globus-repo to `'latest'`
- [puppet] Changed z-00-rsnt_arch consul-template to produce a single value
- [puppet] Stopped installation of CUDA when there is no nvidia device
- [puppet] Fixed PowerTools repo filename for CentOS Linux 8
- [puppet] Bumped puppet-jupyterhub version to 3.7.2

### Removed
- Removed version from the provider config block
- [azure] Remove version set from azure provider

## [9.1] 2020-11-19

### Added
- Added Terraform variable verification for `cluster_name` and `guest_passwd`
- Added `mokey` subdomain to the DNS record generator list
- Added documentation on creating account with Mokey
- [puppet] Integrated UBCCR's project [Mokey](https://github.com/ubccr/mokey)  to allow users to create and manage their account on the cluster using a web portal
- [puppet] Added two daemons `mkhome` and `mkproject` that watch slapd log output for new users and groups and create
home, scratch and project directory plus Slurm account automatically
- [puppet] Added Magic Castle custom login template to JupyterHub, which include a new `Create account` link when user signup is allowed
- [puppet] Added classes `profile::accounts` and `profile::accounts::guests` to handle account creation

### Changed
- [puppet] Updated puppet-jupyterhub version to 3.7.1
- [puppet] Updated `kinit_wrapper` logic to avoid issue with multiple process using the same Kerberos cached credentials

### Removed
- [puppet] Remove class `profile::freeipa::guest_accounts` replaced by `profile::accounts::guests`

## [9.0] 2020-11-17

### Changed
- Upgrade to Terraform 0.13, with a new minimum requirement of 0.13.4

## [8.5] 2020-11-16

### Added
- [puppet] Added Duo MFA classes and on/off switches for management, login and compute nodes.

### Changed
- [puppet] Refactored logic identifying the presence of an NVIDIA GPU to consider memory instead of instance name.
- [puppet] Updated the version of most modules installed with Puppetfile
- [puppet] Fixed permissions of nvidia-modprobe when installing Arbutus' `nvidia-vgpu-tools` rpm.

## [8.4] 2020-11-10

### Changed
- [puppet] Updated puppet-jupyterhub version to v3.5.1

## [8.3] 2020-10-21

### Changed
- Fixed puppetenv_rev default value when creating Magic Castle release (Commit bf30e13036)
- [puppet] Bump puppet-jupyterhub version to v3.4.2
- [puppet] Fixed freeipa issue when an ip was already recorded in the DNS and a new instance was joining the realm with the same ip ([puppet-magic_castle issue #69](https://github.com/ComputeCanada/puppet-magic_castle/issues/69))

## [8.2] 2020-10-14

### Added
- [puppet] Added Cloudflare load balancer cvmfs_acl_regex (issue #64)
- [puppet] Added SELinux policy to allow fail2ban to ban using route (issue #65)

### Changed
- Fixed AWS, Azure, GCP and OVH examples that were incorrectly referring to openstack module
- [cloud-init] Bumped puppetserver to 6.13.0 and puppetagent to 6.18.0
- [puppet] Replaced homemade template of squid.conf by usage of puppet-squid module
- [puppet] Bumped puppet-jupyterhub to v3.4.1
- [puppet] Fixed slurmctld dependency to cluster registration in slurmdbd
- [puppet] Fixed ipa_create_user password configuration

## [8.1] 2020-07-29

### Added
- Added ability to generate an ssh keypair to upload files with Terraform file provisioner.
- [puppet] Added options in hieradata to configure CVMFS repos

### Changed
- Activated VPC DNS support in AWS (issue #108)
- Fixed documentation in multiple sections (PR #92, #93, #97, #98, #101, #106)
- Fixed DNS section of AWS example (PR #108)
- [puppet] Replaced homemade template of squid.conf by usage of puppet-squid module

## [8.0] 2020-06-19

Following release of CentOS 8 2004, AWS now provides an official CentOS 8 image that
has been tested and is functional with Magic Castle 8.0.

### Added
- Added the login node ids as output of the main Magic Castle Terraform module.
- Added a trigger to DNS module deploy_certs based on login node ids. If there is a modification to one of the login node state,
the certificates will be uploaded to the corresponding login node, without having to taint the `deploy_certs` resource manually
(PR #88).
- Added try function around access to index 0 of resource array to limit errors when destroying resources.
- [puppet] Added a resource in `profile::base` to remove terraform `local-exec` leftover empty scripts in /tmp.

### Changed
- [puppet] Id of the accounts created in FreeIPA now start at UID_MAX defined `/etc/login.defs`. (commonly 60000 instead of 50000)
- [puppet] fail2ban configuration is now done with puppet-fail2ban module. The `sshd` jail is now named `ssh-route`.
- [cloud-init] Bumped puppetserver to 6.12.0 and puppetagent to 6.16.0.
- Puppet hieradata yaml files are now uploaded with Terraform file provisioner instead of being embedded in mgmt1 userdata.
This means a change to the number of users, the guest password, or the hieradata variable no longer trigger a rebuild of mgmt1
but only a reupload of YAML files (PR #89)
- [docs] Various fixes (Issues #87, #92, #93)

### Removed
- Hieradata has been removed from puppetmaster.yaml template.

## [7.3] 2020-06-04

This release introduces three main features:
- Add support for Slurm 20
- Add support for CentOS 8. Tested functional on GCP and OpenStack. AWS and Azure do not provide
an official CentOS 8 image with cloud-init support at the moment of this release.
- Add support for Compute Canada Arbutus Cloud NVIDIA VGPUs (flavor `vgpu-...`).

### Changed
- Improved main documentation.
- [AWS] Most resources if not all now have the name of the cluster as a prefix in their name
- [OpenStack] Simplified volume attachment count computation
- [puppet] Slurm plugin spank-cc-tmpfs_mounts is now installed from copr yumrepo
- [puppet] Fixed order of slurm packages install
- [puppet] Exec resource in charge of creating the slurm cluster in slurmdbd now returns 0 if the cluster already exists
- [puppet] `consul-template` class initialization is now entirely in hieradata file `common.yaml`.
- [puppet] CentOS 8 support: replaced notification of `nfs-idmap.service` by notification of `nfs-server.service`.
- [puppet] CentOS 8 support: replaced `pdsh` by `clustershell`
- [puppet] CentOS 8 support: rpc_nfs_args is now only defined if os is CentOS 7.
- [puppet] CentOS 8 support: `ipa_create_user.py` now use `/usr/libexec/platform-python` instead of `/usr/bin/env python`.
- [puppet] CentOS 8 support: Replaced Python 2 `unicode` calls in `ipa_create_user.py` by six's `text_type`
- [puppet] CentOS 8 support: Moved list of nvidia package names from class profile::gpu to hieradata. List now depends on CentOS version.
- [puppet] CentOS 8 support: Moved FreeIPA `regen_cert_cmd` value to hieradata. Command now depends on CentOS version.
- [puppet] Bumped puppet-jupyterhub version to 3.3.2
- [puppet] Update nvidia driver fact to make sure at most one version is in the output
- [puppet] Changed logic of `nvidia_grid_vgpu` fact to just check if the instance flavor includes `vgpu` in its name
- [puppet] CentOS 8 support: Moved default loaded CVMFS modules to hieradata. Module list now depends on CentOS version
- [puppet] CentOS 8 support: Fixed nfs clean rbind execstop warning
- [puppet] Replaced tcp_con_validator to check if slurmdbd is running by a wait_for resource on slurmdbd.log regex
- [puppet] CentOS 8 support: Fixed package name in nvidia-driver-version fact.
- [cloud-init] Replaced `reboot -n` in `runcmd` by `power_state` with reboot now. This makes sure final stage of cloud-init is applied before reboot.
- [gcp] CentOS 8 support: rewrote `install_cloudinit.sh` to avoid network issue at boot and install cloud-init only for the time needed. (issue #85)

### Added
- [puppet] Added support for CentOS 8 when selecting Slurm yumrepo
- [puppet] Slurm 20 support: Added `slurm_version` variable to hieradata. It can be either 19 or 20.
- [puppet] Slurm 20 support: Added PlugStackConfig parameter to slurm.conf
- [puppet] Added slurm-perlapi package to `profile::base::slurm`
- [puppet] Added exec to initialize cvmfs default.local with consul-template.
- [puppet] Added a default node1 in slurm.conf when no slurmd has been registered yet in consul
- [puppet] Added a require on Epel yumrepo for package fail2ban-server
- [puppet] Added class profile::fail2ban::install
- [puppet] CentOS 8 support: Added dependency on puppet-epel to install epel yumrepo
- [puppet] CentOS 8 support: Enabled powertools repo
- [puppet] CentOS 8 support: Enabled idm:DL1 stream
- [puppet] CentOS 8 support: Added network-scripts package when os is CentOS 8
- [puppet] CentOS 8 support: Added munge_socket selinux policy to allow confined user to submit jobs
- [puppet] Added class `profile::gpu::install`
- [puppet] Added a requirement on epel yumrepo for singularity package.
- [puppet] Added a requirement for slurm exec `create_account` on slurm exec `add_cluster`
- [puppet] CentOS 8 support: added class `profile::mail::server`
- [puppet] Added a requirement on yumrepo epel to class `jupyterhub` in `profile::jupyterhub::hub`
- [puppet] Added support for Compute Canada Arbutus Cloud VGPUs

### Removed
- [puppet] Removed notify to `slurmctld` from slurm::accounting exec `add_cluster`.

## [7.2] 2020-05-20

### Changed
- Reverted type of image variable from string to any because Azure image input is a map.

## [7.1] 2020-05-20

### Changed
- [GCP] Fixed a typo in disk paths that prevented creation of project and scratch volume
- [GCP] Increased the root disk size in the example to 20GB. This is the new minimum for centos7 image.
- Bumped minimum requirements to 0.12.21 in all versions.tf files.
- [puppet] Bumped most module versions to latest in Puppetfile
- [puppet] Bumped consul and consul-template version to latest available

### Added
- Documentation on variables specific to the commercial cloud providers
- Documentation on hieradata
- Documentation on firewall_rules
- Description and types to all terraform variables

## [7.0] 2020-05-18

### Changed
- Established a distinction in variables between puppetmaster and mgmt1 - allowing puppetmaster role to be assigned to another instance.
- Bumped minimum requirement of terraform to 0.12.21 (issue #77)
- Numerous doc fixes
- Added a section on related projects in README.md
- [Azure] Updated Azure infrastructure.tf to use Azure provider 2.0.0 (issue #62)
- [cloud-init] Set puppet-agent and puppet-server version to 6.13 and 6.9
- [cloud-init] Renamed cloud-init YAML files to `puppetagent.yaml` and `puppetmaster.yaml`
- [OpenStack] Fixed volume size computation regression introduced in commit c09ea17d
- [puppet] Defined selinux context for /scratch as home_root_dir
- [puppet] Defined selinux context for /project as home_root_dir
- [puppet] Improved cuda facts to avoid issue when html index is incomplete
- [puppet] Updated package names in gpu module and facts
- [puppet] Generalized gpu module cuda repo link composition
- [puppet] Replaced package by ensure_packages for kernel-devel in gpu
- [puppet] Updated version of puppet-jupyterhub to v3.3.0
- [puppet] Improved FreeIPA client installation waiting conditions to limit failure
- [puppet] Disabled root jobs in slurm.conf]
- [puppet] Added nosuid to client nfs mount options
- [puppet] Activated root_squash for all nfs exports
- [puppet] Changed URL for the source of `cc-tmpfs_mount.so`
- [puppet] Updated derdanne/nfs version in Puppetfile
- [puppet] Made profile::base a requirement of profile::nfs::server
- [puppet] Defined servername param for apache in reverse_proxy

### Added
- [Azure] Added variable to allow usage of an existing resource group based on its name (issue #72)
- [cloud-init] Enabled puppet agent postrun command in cloud-init
- [puppet] mgmt1 volumes formatting is now handled by `profile::nfs::server` class
- [puppet] Added logic to define, mount and format nfs shared volumes with lvm
- [puppet] Added README.md
- [puppet] Fixed regression introduced in 630a04
- [puppet] Added possibility to manage jail activation and ignore_ip with hierada
- [puppet] Added profile classes for JupyterHub: `profile::jupyterhub::node` and `profile::jupyterhub::hub`
- [puppet] Added variable to allow definition of lmod default modules with hieradata
- [puppet] Configured lmod default modules to start with gcc and openmpi
- [puppet] Added ability to receive last puppet run output by email through puppet postrun script
- [puppet] Added support for NVIDIA GRID vGPU
- [puppet] Added class `profile::base::azure` for logic specific to Azure

### Removed
- [cloud-init] Removed volumes formatting, partitioning and mounting from mgmt cloud-init
- [puppet] Removed condition on gpu count in nvidia_driver_vers
- [puppet] Removed mkhomedir from FreeIPA client installation parameters

## [6.4] - 2020-03-11

### Changed
- [cloud-init] Hardcoded the version of puppet-agent (6.13.0) and puppetserver (6.9.1).

## [6.3] - 2020-03-09

### Added
- Added random_uuid to generate a random consul token
- [travis] Added init and validation of dns/gcloud module
- [cloud-init] Added bootstrap installation of consul-server in cloud-init
- [puppet] Added slurmd restart when node is missing from sinfo
- [puppet] Introduced class `profile::workshop::mgmt`. The class allow to unzip an archive in all guest accounts
- [puppet] Added profile::workshop::mgmt to mgmt in site.pp
- [puppet] Defined consul::service for slurmd, slurmctld slurmdbd, rsyslog, cvmfs client, and squid. This in conjunction
with consul-template, allow these services to be removed from the config files when the instance that was running the
service is halted. For example, if a compute node is shutdown or remove, it will no longer appear in `sinfo` output.

### Changed
- [cloud-init] Turned off puppet agent reporting in cloud-init
- [cloud-init] [puppet] Renamed user_hieradata as user_data
- [cloud-init] Volume formatting and mounting is now conditional on the hostname being `mgmt1`
- [OpenStack] Fixed port_node resource name template
- [puppet] Updated puppet-jupyterhub version to v1.8.1
- [puppet] Consul and consul-template version are now defined in hieradata
- [puppet] Changed node_exported consul service name to node-exported to remove warning

### Removed
- [puppet] Removed unused key from terraform_data
- [puppet] Removed stage in mgmt site.pp

## [6.2] - 2020-03-01

### Added
- Added an error message in cloud-init dev avail while loops
- Added gcloud dns module to AWS, Azure and OVH examples.
- [puppet] Added a slurmd restart when node hostname is missing from sinfo output.
- [puppet] Added class profile::workshop::mgmt to deploy files to guest user homes
- [puppet] Added class profile::workshop::mgmt to mgmt1 in site.pp

### Changed
- [OpenStack] All resources, including instances, have now a name that starts with the cluster name.
This does not affect the instances' hostname
- [puppet] Update puppet-jupyterhub version to v1.7

## [6.1] - 2020-02-27

Fix travis release procedure. 6.0 release bundles contained the wrong module source in main.tf.

## [6.0] - 2020-02-26

Terraform >= 0.12.21 is now required. Usage of the function `subtract` requires at least 0.12.21.

### Added
- Added the optional key `prefix` to the `instance["node"]` map (issue #29)
- [cloud-init] Added removal of ifcfg file with no corresponding nic (issue #61)
- [puppet] Added optional prefix to node regex in site.pp

### Changed
- `instance["node"]` is now a list. This allows the spawning of compute nodes with various instance types (issue #29)
- release.sh is now the only script for creating a release on any platform.
- [Azure] Renamed azurerm_virtual_machine nodevm to node (issue #55)
- [AWS] Replaced aws volume device name by volume id (issue #60)
- [gcp] Renamed gcp var.project_name to var.project (issue #53)
- [puppet] Upgraded puppet-prometheus to 8.2.1
- [puppet] Remove Name=gpu from gres.conf template ([puppet-magic_castle issue #27](https://github.com/ComputeCanada/puppet-magic_castle/issues/27))

## [5.8] - 2020-02-24

### Added
- [Azure] Added `root_disk_size=30` in the example (issue #43)
- [Azure] Added ssh_keys to instances as it is mandatory (issue #44)
- [cloud-init] Added volume attachment verification loops in mgmt cloud-init (issue #54)
- [GCP] Added gcloud dns module to gcp example (issue #37)
- [GCP] Added prefix to the name of volumes and ipv4 (issue #49)
- [OpenStack] Added os_int_subnet variable. The variable is used to force to use a specific subnet with Openstack.

### Changed
- Changes to image variable are now ignored after cluster is built.
- Fixed release scripts to solve bug where multiple `version` variable were present (issue #38)
- [Azure] Updated the example to use the most recent OpenLogic CentOS 7 image (issue #42)
- [Azure] Resources names are now prefixed with the cluster name
- [Azure] Azure public_ip now outputs a list of all login ip addresses
- [cloud-init] Replaced timezone in cloud-init to UTC (issue #51)
- [GCP] Zone variable is now optional. The zone is randomly selected in the zones available for the region if left blank.
- [GCP] Instances internal DNS are now configured to use zonal DNS. The internal DNS hostname is not used, but the change reduced
the DHCP time lease from 24 to 1 hour. This helps when debugging DHCP issue
- [puppet] CC CVMFS repo is now configured from latest RPM repo (issue [puppet-magic_castle issue #19](https://github.com/ComputeCanada/puppet-magic_castle/pull/19))
- [puppet] Increased the squid maximum_object_size ([puppet-magic_castle issue #20](https://github.com/ComputeCanada/puppet-magic_castle/issues/20))
- [puppet] Updated globus rpm repo name
- [puppet] Updated fail2ban config to make it work with 0.10.x ([puppet-magic_castle issue #25](https://github.com/ComputeCanada/puppet-magic_castle/issues/25))
- [puppet] Replaced file by exec to create singularity symlink ([puppet-magic_castle issue #24](https://github.com/ComputeCanada/puppet-magic_castle/issues/24))
- [puppet] Replaced timezone in cloud-init to UTC ([puppet-magic_castle issue #26](https://github.com/ComputeCanada/puppet-magic_castle/issues/26))
- [puppet] Added service network and notify on NetworkManager purge (issue #50)

### Removed
- [GCP] Zone variable is no longer in the example as it is now optional.


## [5.7] - 2020-01-16

### Added
- [AWS] Added `skip_destroy = True` to EBS attachment resources to avoid stalling destroy command.
- [DNS] Added a `dtn` entry for the Globus endpoint.
- [DNS] Added an `ipa` entry that provides access to FreeIPA webpage.
- [puppet] Added a `profile::reverse_proxy` class that configure Apache vhost for JupyterHub, FreeIPA, Globus, etc.
- [puppet] Added service nvidia-persistenced to module gpu.pp.
- [puppet] Added `drain` to states that spawns an scontrol in slurm module.
- [main.tf] Added `hieradata` variable that allow the injection of custom values in puppet hieradata from Terraform.

### Changed
- [AWS] Changed mgmt and login instances from using `associate_public_ip_address` to using an AWS Elastic IP.
- [AWS] Updated example AMI and minimum instance type for mgmt.
- [AWS] Fixed module's syntax for Terraform 0.12.
- [AWS] Made `availability_zone` optional. If zone is not provided, it will be randomly selected amongst the zones available for the selected region.
- [AWS] Changed root disk type from `standard` to `gp2`.
- [AWS] Enabled ebs_optimized for all instances.
- [AWS] Changed SSH keyname from `slurm-cloud-key` to `${cluster_name}-key`
- [cloud-init] Made puppet yumrepo install function of the CentOS major version.
- [cloud-init] Added blacklisting of nouveau driver in kernel cmdline option.
- [DNS] DNS records are now produced by the `record_generator` module instead of listing records in each DNS provider module.
- [puppet] Changed Globus authentication method from MyProxy to OAuth.
- [puppet] Updated puppet-jupyterhub version from v1.1 to v1.6.
- [puppet] Replaced deprecated package name dkms-nvidia by kmod-nvidia-latest-dkms.
- [puppet] Replaced every reference to facts of `eth0` by facts of interface index 0.
- [puppet] Disabled dkms autoinstall timeout in gpu.

### Removed
- [puppet] Removed include of jupyterhub::reverse_proxy in site.pp for login.

## [5.6] - 2019-11-27

### Added
- [DNS] Added support for Google Cloud DNS (PR #24)
- Added a release script compatible with BSD tools - `release.bsd.sh`

### Changed
- [DNS] Changed the login record A pattern from `clustername#.domain` to `login#.clustername.domain` where `#` is the login node index.
- [DNS] Moved wildcard certificate creation from cloudflare to an acme module shared by all dns modules.
- [DNS] Replaced usage of 0-index on array by call to `distinct` (issue #26).
- [DNS] A `jupyter.${cluster_name}.${domain_name}` record is now added for each login instead of just login1.
- Changed the management and login node naming scheme to match node naming. `mgmt01` is now `mgmt1` and `login01` is now `login1`.
- [puppet] Fix puppet-jupyterhub version to v1.1 instead of master branch.

### Removed
- [DNS] Removed creation of SSHFP SHA1 records (issue #22)

## [5.5] - 2019-11-15

### Added
- [docs] Added details on how to use CloudFlare API Token in README.md
- [docs] Added details on which Open RC File to download when using OpenStack
- [DNS] Added an email variable to the dns module.
- [puppet] Added logic to set RSNT_ARCH variable based on the common CPU
instruction extensions available amongst all CVMFS clients using consul.

## [5.4] - 2019-10-23

### Fixed
- [OpenStack] Fix image_id condition for login and node
- [CloudFlare] Update to CloudFlare provider 2.0 and pinned the version in dns.tf.

## [5.3] - 2019-09-30

### Added
- [puppet] Added hbac rule to limit access to mgmt instances from IPA users (issue #13)
- [puppet] Added token based ACL to consul to limit access to the key-value store (issue #11)

### Changed
- [puppet] Activate selinuxuser_tcp_server boolean to allow confined users to run MPI jobs (issue #12)
- [puppet] FreeIPA OTP activation command is now subscribed to server install exec

### Fixed
- [OpenStack] Set the image_id to null when the root disk is a volume to avoid false detection of change by Terraform

## [5.2] - 2019-09-19

### Added
- Travis CI automated testing for Terraform and Puppet files
- Travis CI build status is now at the beginning of README.md
- [docs] Added contribution section to README.md
- [OVH] Added a Terraform file for network related resources
- [OpenStack] Added a Terraform file for network related resources
- [cloud-init] Added removal of firewalld package in mgmt.yaml
- [docs] Added docs on building SELinux enabled image for OVH cloud
- [OpenStack] Added the definition of a root disk block device with condition on flavor choice and root disk size
- [GCP] Added the ability to set the boot disk size with `var.root_disk_size`
- [Azure] Added the ability to set the os storage volume size with `var.root_disk_size`
- [AWS] Added the ability to set the root disk size with `var.root_disk_size`
- [docs] Added documentation on variable `root_disk_size`
- [puppet] Added myproxy and gridftp as service in globus module

### Changed
- Release script now takes only one version number
- Release script now fixes the Terraform providers' version
- [docs] Updated globus documentation
- [docs] Renamed developers docs
- [OVH] OVH infrastructure file is now a symlink to the OpenStack infrastructure file
- [puppet] Globus is now installed only if globus_user/password is defined in the hieradata
- [puppet] Globus endpoint name is now set based on the domain name instead of the instance hostname
- [puppet] FreeIPA ip address parameter on mgmt is now fixed to eth0 interface
- [puppet] Firewall chains and rules that were not set by puppet are now purged
- [puppet] Configure network, netmask and ip to always map to eth0 interface
- [puppet] Configure slurmctld ip address to eth0 to fix issue when there more than one NIC

### Removed
- Removed version number from documentation

### Fixed
- [AWS] Fixed dependency cycle with volumes
- [AWS] Fixed firewall definition
- [AWS] Fixed dependency cycle with mgmt ip addresses
- [OVH] Fixed dependency cycle
- [docs] Fixed typos and rfc links

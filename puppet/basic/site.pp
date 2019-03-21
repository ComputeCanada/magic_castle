node default {
  include profile::base
  include profile::freeipa::client
  include profile::nfs::client
  include profile::rsyslog::client
  include profile::slurm::submitter
}

node /^login\d+$/ {
  include profile::base
  include profile::freeipa::client
  include profile::nfs::client
  include profile::rsyslog::client
  include profile::slurm::submitter
}

node /^mgmt\d+$/ {
  include profile::slurm::controller
  include profile::slurm::accounting
  include profile::nfs::server
  include profile::freeipa::server

  include profile::base
  include profile::freeipa::guest_accounts
  include profile::rsyslog::server
}

node /^node\d+$/ {
  include profile::base
  include profile::freeipa::client
  include profile::nfs::client
  include profile::rsyslog::client
  include profile::slurm::node

  Class['profile::freeipa::client'] -> Class['profile::nfs::client'] -> Class['profile::slurm::node']
}

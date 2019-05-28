node default {
  include profile::base
  include profile::freeipa::client
  include profile::rsyslog::client
}

node /^login\d+$/ {
  include profile::base
  include profile::freeipa::client
  include profile::nfs::client
  include profile::rsyslog::client
  include profile::slurm::submitter
  include profile::fail2ban
}

node /^mgmt01$/ {
  include profile::base
  include profile::freeipa::server
  include profile::rsyslog::server
  include profile::slurm::controller
  include profile::nfs::server

  include profile::freeipa::guest_accounts
  include profile::slurm::accounting
  include profile::squid::server
}

node /^mgmt0*(?:[2-9]|[1-9]\d\d*)$/ {
  include profile::base
  include profile::freeipa::client
  include profile::rsyslog::client
}

node /^node\d+$/ {
  include profile::base
  include profile::freeipa::client
  include profile::nfs::client
  include profile::rsyslog::client
  include profile::gpu
  include profile::slurm::node

  Class['profile::freeipa::client'] -> Class['profile::nfs::client'] -> Class['profile::slurm::node']
}

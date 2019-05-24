node default {
  include profile::base
  include profile::freeipa::client
  include profile::rsyslog::client
}

node /^login01$/ {
  include profile::base
  include profile::freeipa::client
  include profile::nfs::client
  include profile::cvmfs::client
  include profile::rsyslog::client
  include profile::slurm::submitter
  include profile::globus::base
  include profile::singularity
  include jupyterhub
  include profile::fail2ban
}

node /^login0*(?:[2-9]|[1-9]\d\d*)$/ {
  include profile::base
  include profile::freeipa::client
  include profile::nfs::client
  include profile::cvmfs::client
  include profile::rsyslog::client
  include profile::slurm::submitter
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
  include profile::cvmfs::client
  include profile::rsyslog::client
}

node /^node\d+$/ {
  include profile::base
  include profile::freeipa::client
  include profile::nfs::client
  include profile::rsyslog::client
  include profile::cvmfs::client
  include profile::gpu
  include profile::slurm::node
  include profile::singularity
  include jupyterhub::node

  Class['profile::freeipa::client'] -> Class['profile::nfs::client'] -> Class['profile::slurm::node']
}

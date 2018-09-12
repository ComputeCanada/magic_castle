class common {
  include stdlib

  package { 'vim':
    ensure => 'installed'
  }
  package { 'rsyslog':
    ensure => 'installed'
  }

  service { 'firewalld':
    ensure => 'stopped',
    enable => 'mask'
  }

  package { ['iptables', 'iptables-services'] :
    ensure => 'installed'
  }

  yumrepo { 'epel':
    baseurl        => 'http://dl.fedoraproject.org/pub/epel/$releasever/$basearch',
    enabled        => "true",
    failovermethod => "priority",
    gpgcheck       => "false",
    gpgkey         => "file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL",
    descr          => "Extra Packages for Enterprise Linux"
  }

  yumrepo { 'elrepo':
    descr    => "ELRepo.org Community Enterprise Linux Repository - el7",
    baseurl  => 'http://muug.ca/mirror/elrepo/elrepo/el7/$basearch/',
    enabled  => "true",
    gpgcheck => "false",
    gpgkey   => "file:///etc/pki/rpm-gpg/RPM-GPG-KEY-elrepo.org",
    protect  => "false"
  }

  class { 'slurm::base':
    munge_key => "abcdefghijklmnopqrstuvwxyz012345"
  }
}

node default {
  include common

}

node /^mgmt\d+$/ {
  include common
  $masklen = netmask_to_masklen("$netmask")
  $cidr    = "$network/$masklen"

  package { "ipa-server-dns":
    ensure => "installed"
  }

  # rsyslog
  service { 'rsyslog':
    ensure => running,
    enable => true
  }

  file_line { 'rsyslog_modload_imtcp':
    ensure => present,
    path   => "/etc/rsyslog.conf",
    match  => '^#$ModLoad imtcp',
    line   => '$ModLoad imtcp',
    notify => Service['rsyslog']
  }
  file_line { 'rsyslog_InputTCPServerRun':
    ensure => present,
    path   => "/etc/rsyslog.conf",
    match  => '^#$InputTCPServerRun 514',
    line   => '$InputTCPServerRun 514',
    notify => Service['rsyslog']
  }

  # Squid
  package { "squid":
    ensure => "installed"
  }

  service { 'squid':
    ensure => 'running',
    enable => 'true'
  }

  file { '/etc/squid/squid.conf':
    ensure  => 'present',
    content => file('squid/squid.conf')
  }

  # Shared folders
  file { '/scratch' :
    ensure => directory,
  }
  file { ['/project', '/project/6002799', '/project/6002799/photos'] :
    ensure => directory
  }

  file { '/project/6002799/photos/KSC2018.jpg':
    ensure => 'present',
    source => "https://images-assets.nasa.gov/image/KSC-20180316-PH_JBS01_0118/KSC-20180316-PH_JBS01_0118~orig.JPG"
  }

  file { "/project/6002799/photos/VAFB2018.jpg":
    ensure => 'present',
    source => "https://images-assets.nasa.gov/image/VAFB-20180302-PH_ANV01_0056/VAFB-20180302-PH_ANV01_0056~orig.jpg"
  }

  # NFS
  class { '::nfs':
    server_enabled => true,
    nfs_v4 => true,
    nfs_v4_export_root  => "/",
    nfs_v4_export_root_clients => "$cidr(rw,sync,no_root_squash,no_all_squash)"
  }
  nfs::server::export{ ['/etc/slurm', '/home', '/project', '/scratch'] :
    ensure  => 'mounted',
  }

}

node /^login\d+$/ {

}

node /^node\d+$/ {

}

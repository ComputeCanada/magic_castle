class common {
  include stdlib

  class { selinux:
    mode => 'enforcing',
    type => 'targeted',
  }

  service { 'rsyslog':
    ensure => running,
    enable => true
  }

  class { '::swap_file':
    files => {
      '/mnt/swap' => {
        ensure   => present,
        swapfile => '/mnt/swap',
        swapfilesize => '1 GB',
      },
    },
  }

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

class client {
  # rsyslog
  file_line { 'remote_host':
    ensure => present,
    path   => "/etc/rsyslog.conf",
    match  => '^#\*.\* @@remote-host:514',
    line   => '*.* @@mgmt01:514',
    notify => Service['rsyslog']
  }

  # FreeIPA
  $admin_passwd = "abcdefghijk0123456"
  $domain = "phoenix.calculquebec.cloud"
  $mgmt01_ip = "10.0.0.9"

  package { 'ipa-client':
    ensure => 'installed'
  }
  file_line { 'resolv_search':
    ensure => present,
    path   => "/etc/resolv.conf",
    match  => "search",
    line   => "search $domain"
  }
  file_line { 'resolv_nameserver':
    ensure  => present,
    path    => "/etc/resolv.conf",
    after   => "search $domain",
    line    => "nameserver $mgmt01_ip",
    require => File_line['resolv_search']
  }

  exec { 'set_hostname':
    command => "/bin/hostnamectl set-hostname $hostname.$domain",
    unless  => "/usr/bin/test `hostname` = $hostname.$domain"
  }

  # TODO: add chattr +i /etc/resolv.conf
  exec { 'ipa-client-install':
    command => "/sbin/ipa-client-install \
                --mkhomedir \
                --ssh-trust-dns \
                --enable-dns-updates \
                --unattended \
                -p admin \
                -w $admin_passwd",
    tries => 10,
    try_sleep => 30,
    require => [File_line['resolv_nameserver'],
                File_line['resolv_search'],
                Exec['set_hostname']],
    creates => '/etc/ipa/default.conf'
  }

  # NFS
  $server = 'mgmt01'
  class { '::nfs':
    client_enabled => true,
    nfs_v4_client  => true,
  }
  selinux::boolean { 'use_nfs_home_dirs': }
  nfs::client::mount { '/home':
      server => 'mgmt01',
      share => 'home'
  }
  nfs::client::mount { '/project':
      server => 'mgmt01',
      share => 'project'
  }
  nfs::client::mount { '/scratch':
      server => 'mgmt01',
      share => 'scratch'
  }
  nfs::client::mount { '/etc/slurm':
      server => 'mgmt01',
      share => 'slurm'
  }

  # CVMFS
  package { 'cvmfs-repo':
    name     => 'cvmfs-release-2-6.noarch',
    provider => 'rpm',
    ensure   => 'installed',
    source   => 'https://ecsft.cern.ch/dist/cvmfs/cvmfs-release/cvmfs-release-latest.noarch.rpm'
  }
  package { 'cc-cvmfs-repo':
    name     => 'computecanada-release-1.0-1.noarch',
    provider => 'rpm',
    ensure   => 'installed',
    source   => 'https://package.computecanada.ca/yum/cc-cvmfs-public/Packages/computecanada-release-1.0-1.noarch.rpm'
  }
  package { ['cvmfs', 'cvmfs-config-computecanada', 'cvmfs-config-default', 'cvmfs-auto-setup']:
    ensure => 'installed',
    require => [Package['cvmfs-repo'], Package['cc-cvmfs-repo']]
  }
  file { '/etc/cvmfs/default.local':
    ensure  => 'present',
    content => file('cvmfs/default.local'),
    require => Package['cvmfs']
  }
  file { '/etc/profile.d/z-00-computecanada.sh':
    ensure  => 'present',
    content => file('cvmfs/z-00-computecanada.sh'),
    require => File['/etc/cvmfs/default.local']
  }
  service { 'autofs':
    ensure  => running,
    enable  => true,
    require => File['/etc/cvmfs/default.local']
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

  # FreeIPA
  $admin_passwd = "abcdefghijk0123456"
  $domain = "phoenix.calculquebec.cloud"
  $realm = upcase($domain)
  $ip = $facts['networking']['ip']
  exec { 'ipa-server-install':
    command => "/sbin/ipa-server-install \
                --setup-dns \
                --hostname $hostname.$domain \
                --ds-password $admin_passwd \
                --admin-password $admin_passwd \
                --mkhomedir \
                --ssh-trust-dns \
                --unattended \
                --forwarder=1.1.1.1 \
                --forwarder=8.8.8.8 \
                --ip-address=$ip \
                --no-host-dns \
                --no-dnssec-validation \
                --real=$realm",
    creates => '/etc/ipa/default.conf',
    timeout => 0,
    require => Class['::swap_file']
  }

  # rsyslog
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
    content => epp('squid/squid.conf', {'cidr' => $cidr})
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
    nfs_v4_export_root  => "/export",
    nfs_v4_export_root_clients => "$cidr(ro,fsid=root,insecure,no_subtree_check,async,root_squash)"
  }
  nfs::server::export{ ['/etc/slurm', '/home', '/project', '/scratch'] :
    ensure  => 'mounted',
    clients => "$cidr(rw,sync,no_root_squash,no_all_squash)"
  }

  # Slurm Controller
  package { ['slurm-slurmctld']:
    ensure => 'installed',
  }
  service { 'slurmctld':
    ensure  => 'running',
    enable  => true,
    require => Package['slurm-slurmctld']
  }

}

node /^login\d+$/ {
  include common
  include client
  # JupyterHub
  include jupyterhub

}

node /^node\d+$/ {
  include common
  include client
  
  package { 'kmod-nvidia-390.48':
    ensure => 'installed'
  }
  
  package { 'slurmd':
    ensure => 'installed'
  }

  service { 'slurmd':
    ensure => 'running',
    enable => 'true'
  }

  exec { 'slurm_config':
    command => "/bin/flock /etc/slurm/node.conf.lock sed -i 's/NodeName=$hostname.*/$(slurmd -C | head -n 1)/g'",
  }

}

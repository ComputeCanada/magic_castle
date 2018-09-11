node default {
  include slurm
  
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
    baseurl        => "http://dl.fedoraproject.org/pub/epel/\$releasever/\$basearch",
    enabled        => "true",
    failovermethod => "priority",
    gpgcheck       => "false",
    gpgkey         => "file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL",
    descr          => "Extra Packages for Enterprise Linux"
  }

  yumrepo { 'elrepo':
    descr    => "ELRepo.org Community Enterprise Linux Repository - el7",
    baseurl  => "http://muug.ca/mirror/elrepo/elrepo/el7/\$basearch/",
    enabled  => "true",
    gpgcheck => "false",
    gpgkey   => "file:///etc/pki/rpm-gpg/RPM-GPG-KEY-elrepo.org",
    protect  => "false"
  }

  class { 'slurm::base':
    munge_key => "abcdefghijklmnopqrstuvwxyz"
  }

}

node /^mgmt\d+$/ {

}

node /^login\d+$/ {

}

node /^node\d+$/ {

}


class slurm::base (String $munge_key) {
  group { 'slurm':
    ensure => 'present',
    gid    =>  '2001'
  }

  user { 'slurm': 
    ensure  => 'present',
    groups  => 'slurm',
    uid     => '2001',
    home    => '/var/lib/slurm',
    comment =>  'Slurm workload manager',
    shell   => '/bin/bash',
    before  => Package['slurm']
  }

  group { 'munge':
    ensure => 'present',
    gid    =>  '2002'
  }

  user { 'munge': 
    ensure  => 'present',
    groups  => 'munge',
    uid     => '2002',
    home    => '/var/lib/munge',
    comment =>  'MUNGE Uid N Gid Emporium',
    shell   => '/sbin/nologin',
    before  => Package['munge']
  }

  package { ['munge', 'munge-libs'] :
    ensure  => 'installed',
    require => Yumrepo['epel']
  }

  file { '/var/spool/slurm':
    ensure => 'directory',
    owner  => 'slurm',
    group  => 'slurm'
  }

  file { '/etc/slurm':
    ensure => 'directory',
    owner  => 'slurm',
    group  => 'slurm'
  }

  file { '/etc/munge':
    ensure => 'directory',
    owner  => 'munge',
    group  => 'munge'
  }

  file { '/etc/slurm/cgroup.conf':
    ensure => 'present',
    owner  => 'slurm',
    group  => 'slurm',
    content => file('slurm/cgroup.conf')
  }

  file { '/etc/slurm/epilog':
    ensure  => 'present',
    owner   => 'slurm',
    group   => 'slurm',
    content => file('slurm/epilog')
  }

  file { '/etc/slurm/slurm.conf':
    ensure  => 'present',
    owner   => 'slurm',
    group   => 'slurm',
    content => file('slurm/slurm.conf')
  }

  $node_template = @(END)
<% for i in 1..250 do -%>
NodeName=node<%= i %> State=FUTURE
<% end -%>
END

  file { '/etc/slurm/node.conf':
    ensure  => 'present',
    owner   => 'slurm',
    group   => 'slurm',
    replace => 'false',
    content => inline_template($node_template)
  }

  file { '/etc/slurm/plugstack.conf':
    ensure => 'present',
    owner  => 'slurm',
    group  => 'slurm',
    content => 'required /usr/lib64/slurm/cc-tmpfs_mounts.so bindself=/tmp bindself=/dev/shm target=/localscratch bind=/var/tmp/'
  }

  file { '/etc/munge/munge.key':
    ensure => 'present',
    owner  => 'munge',
    group  => 'munge',
    mode   => '0400',
    content => $munge_key,
    before  => Service['munge']
  }

  service { 'munge':
    ensure => 'running',
    enable => 'true',
    subscribe => File['/etc/munge/munge.key']
  }

  yumrepo { 'darrenboss-slurm':
    enabled             => 'true',
    descr               => 'Copr repo for Slurm owned by darrenboss',
    baseurl             => 'https://copr-be.cloud.fedoraproject.org/results/darrenboss/Slurm/epel-7-$basearch/',
    skip_if_unavailable => 'true',
    gpgcheck            => 1,
    gpgkey              => 'https://copr-be.cloud.fedoraproject.org/results/darrenboss/Slurm/pubkey.gpg',
    repo_gpgcheck       => 0,
  }

  package { 'slurm':
    ensure => 'installed',
    require => Yumrepo['darrenboss-slurm']
  }

  file { 'cc-tmpfs_mount.so':
    source        => 'https://gist.github.com/cmd-ntrf/a9305513809e7c9a104f79f0f15ec067/raw/da71a07f455206e21054f019d26a277daeaa0f00/cc-tmpfs_mounts.so',
    path          => '/usr/lib64/slurm/cc-tmpfs_mounts.so',
    owner         => 'slurm',
    group         => 'slurm',
    mode          => '0755',
    checksum      => 'md5',
    checksum_value => 'ff2beaa7be1ec0238fd621938f31276c',
  }
}

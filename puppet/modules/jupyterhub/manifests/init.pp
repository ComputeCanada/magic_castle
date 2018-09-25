class jupyterhub (String $domain_name = "") {
  selinux::module { 'login':
    ensure    => 'present',
    source_te => 'puppet:///modules/jupyterhub/login.te',
    builder   => 'refpolicy'
  }
  selinux::boolean { 'httpd_can_network_connect': }

  user { 'jupyterhub': 
    ensure  => 'present',
    groups  => 'jupyterhub',
    uid     => '2003',
    home    => '/opt/jupyterhub',
    comment =>  'JupyterHub',
    shell   => '/bin/bash',
  }
  group { 'jupyterhub':
    ensure => 'present',
    gid    =>  '2003'
  }

  class { 'nodejs': 
    repo_url_suffix => '8.x',
  }

  package { 'nginx':
    ensure => 'installed'
  }
  package { 'certbot-nginx':
    ensure => 'installed'
  }
  package { 'python36':
    ensure => 'installed'
  }

  package { 'configurable-http-proxy':
    ensure   => 'installed',
    provider => 'npm'
  }

  file { 'jupyterhub.service':
    path   => '/lib/systemd/system/jupyterhub.service',
    ensure => 'present',
    source => 'puppet:///modules/jupyterhub/jupyterhub.service'
  }

  file { '/etc/sudoers.d/99-jupyterhub-user':
    ensure => 'present',
    source => 'puppet:///modules/jupyterhub/99-jupyterhub-user'
  }
  file { ['/opt', '/opt/jupyterhub', '/opt/jupyterhub/etc', '/opt/jupyterhub/bin']:
    ensure => directory,
    owner  => 'jupyterhub'
  }
  file { 'build_venv_tarball.sh':
    path   => '/opt/jupyterhub/bin/build_venv_tarball.sh',
    ensure => present,
    source => 'puppet:///modules/jupyterhub/build_venv_tarball.sh',
    mode   => '0700'
  }
  file { 'jupyterhub_config.py':
    path   => '/opt/jupyterhub/etc/jupyterhub_config.py',
    ensure => 'present',
    source => 'puppet:///modules/jupyterhub/jupyterhub_config.py',
    mode   => '0600',
    owner  => 'jupyterhub'
  }
  file { 'submit.sh':
    path   => '/opt/jupyterhub/etc/submit.sh',
    ensure => 'present',
    source => 'puppet:///modules/jupyterhub/submit.sh',
    mode   => '0644',
    owner  => 'jupyterhub'
  }  
  exec { 'jupyter_tarball':
    command => "/opt/jupyterhub/bin/build_venv_tarball.sh",
    creates => '/project/jupyter_singleuser.tar.gz',
    require => [File['build_venv_tarball.sh'],
                NFS::Client::Mount['/project'], 
                Service['autofs']]
  }

  # JupyterHub virtual environment
  exec { 'jupyterhub_venv':
    command => '/usr/bin/python36 -m venv /opt/jupyterhub',
    creates => '/opt/jupyterhub/bin/python',
    user    => 'jupyterhub',
    require => Package['python36']
  }
  exec { 'jupyterhub_pip':
    command => '/opt/jupyterhub/bin/pip install --no-cache-dir jupyterhub',
    creates => '/opt/jupyterhub/bin/jupyterhub',
    user    => 'jupyterhub',
    require => Exec['jupyterhub_venv']
  }
  exec { 'jupyterhub_batchspawner':
    command => '/opt/jupyterhub/bin/pip install --no-cache-dir https://github.com/cmd-ntrf/batchspawner/archive/remote_port.zip',
    creates => '/opt/jupyterhub/bin/batchspawner-singleuser',
    user    => 'jupyterhub',
    require => Exec['jupyterhub_pip']
  }

  service { 'jupyterhub': 
    ensure  => running,
    enable  => true,
    require => [Exec['jupyterhub_batchspawner'], 
                File['jupyterhub.service'],
                File['jupyterhub_config.py'],
                File['submit.sh']]
  }

  file { 'jupyterhub.conf':
    path    => '/etc/nginx/conf.d/jupyterhub.conf',
    content => epp('jupyterhub/jupyterhub.conf', {'domain_name' => $domain_name}),
    mode    => '0644',
    notify  => Service['nginx']
  }

  file_line { 'nginx_default_server_ipv4':
    ensure => absent,
    path   => "/etc/nginx/nginx.conf",
    match  => "listen       80 default_server;",
    match_for_absence => true,
    notify => Service['nginx']
  }

  file_line { 'nginx_default_server_ipv6':
    ensure => absent,
    path   => "/etc/nginx/nginx.conf",
    match  => "listen       \[::\]:80 default_server;",
    match_for_absence => true,
    notify => Service['nginx']
  }

  service { 'nginx':
    ensure  => running,
    enable  => true
  }

  if $domain_name != "" {
    exec { 'cerbot-nginx':
      command => "/bin/certbot --nginx --register-unsafely-without-email --noninteractive --redirect --agree-tos --domains $domain_name",
      creates => "/etc/letsencrypt/live/$domain_name/cert.pem",
      require => [Package['certbot-nginx'], Service['nginx']]
    }
  }

}
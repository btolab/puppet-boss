# manage puppetboard
#
# @param python_version
#   set if puppetboard does not have the correct version or support for
#   the platform being deployed
# @param manage_firewall
class boss::profile::puppetboard (
  Optional[String] $python_version = undef,
  Boolean $manage_firewall = true,
) {
  require boss::profile::python

  $host = $facts['networking']['fqdn']
  $ssl_dir = '/etc/puppetlabs/puppet/ssl'

  class { 'puppetboard':
    python_version      => $python_version,
    python_systempkgs   => false,
    manage_virtualenv   => false,
    secret_key          => stdlib::fqdn_rand_string(32),
    enable_catalog      => true,
    groups              => 'puppet',
    puppetdb_host       => $host,
    puppetdb_port       => 8081,
    puppetdb_key        => "${ssl_dir}/private_keys/${host}.pem",
    puppetdb_ssl_verify => "${ssl_dir}/certs/ca.pem",
    puppetdb_cert       => "${ssl_dir}/certs/${host}.pem",
    require             => Package['puppetserver'],
  }
  -> python::pip { 'gunicorn':
    virtualenv => $puppetboard::virtualenv_dir,
    proxy      => $puppetboard::python_proxy,
    owner      => $puppetboard::user,
    group      => $puppetboard::group,
    require    => Python::Pyvenv[$puppetboard::virtualenv_dir],
  }
  ~> systemd::unit_file { 'puppetboard.service':
    content => epp("${module_name}/profile/puppetboard/gunicorn.service", {
        user       => $puppetboard::user,
        group      => $puppetboard::group,
        virtualenv => $puppetboard::virtualenv_dir,
        settings   => $puppetboard::settings_file,
        bind       => '0.0.0.0:9090',
    }),
    enable  => true,
    active  => true,
  }

  if $manage_firewall {
    firewall { '1000 accept - puppetboard':
      dport  => 9090,
      proto  => 'tcp',
      action => 'accept',
    }
  }
}

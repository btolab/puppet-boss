# manage puppetboard
#
class boss::profile::puppetboard {
  require boss::profile::python

  $host = $facts['networking']['fqdn']
  $ssl_dir = '/etc/puppetlabs/puppet/ssl'

  class { 'puppetboard':
    python_systempkgs   => true,
    manage_virtualenv   => false,
    secret_key          => stdlib::fqdn_rand_string(32),
    enable_catalog      => true,
    groups              => 'puppet',
    puppetdb_host       => $host,
    puppetdb_port       => 8081,
    puppetdb_key        => "${ssl_dir}/private_keys/${host}.pem",
    puppetdb_ssl_verify => "${ssl_dir}/certs/ca.pem",
    puppetdb_cert       => "${ssl_dir}/certs/${host}.pem",
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

  firewall { '1000 accept - puppetboard':
    dport  => 9090,
    proto  => 'tcp',
    action => 'accept',
  }
}
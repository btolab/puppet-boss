# manage puppetdb
#
# @param postgres_version
#   major version of postgres to install
# @param version
#   version of puppetdb to install
# @param manage_dnf
#   disable vendor postgresql module
# @param java_mx
#   set java Xmx argument to value
# @param java_ms
#   set java Xms argument to value
# @param manage_firewall
#
class boss::profile::puppetdb (
  Integer $postgres_version,
  String  $version = 'latest',
  Boolean $manage_dnf = false,
  Pattern[/^[0-9]+[kmg]$/] $java_ms = '128m',
  Pattern[/^[0-9]+[kmg]$/] $java_mx = '1g',
  Boolean $manage_firewall = true,
) {
  realize(Boss::Repository['puppet'])
  require boss::profile::openjdk

  $puppet_confdir = '/etc/puppetlabs/puppet'

  # puppetdb module doesn't expose the postgresql::globals parameter
  if $manage_dnf {
    exec { 'disable-dnf-postgresql-module':
      command => '/usr/bin/env dnf module disable -d 0 -e 1 -y postgresql',
      unless  => '/usr/bin/env dnf module --disabled list postgresql',
    }

    Yumrepo <| tag == 'postgresql::repo' |>
    -> Exec['disable-dnf-postgresql-module']
    -> Package <| tag == 'postgresql' |>
  }

  class { 'puppetdb::globals':
    version        => $version,
    puppet_confdir => $puppet_confdir,
  }

  $java_args = ['mx', 'ms'].reduce({}) |$memo, $v| {
    $value = getvar("java_${v}")
    if $value { $memo + { "-X${v}" => $value } } else { $memo }
  }

  class { 'puppetdb':
    listen_address          => '0.0.0.0',
    disable_update_checking => true,
    postgres_version        => String($postgres_version),
    open_listen_port        => true,
    open_ssl_listen_port    => true,
    java_args               => $java_args,
    manage_firewall         => $manage_firewall,
  }
  -> class { 'puppetdb::master::config':
    create_puppet_service_resource => false,
    enable_reports                 => true,
    manage_report_processor        => true,
    strict_validation              => false, # required for bolt apply :(
  }
  -> file { '/opt/puppetlabs/bin/puppet-db':
    ensure => link,
    target => '/opt/puppetlabs/puppet/bin/puppet-db',
  }

  package { 'gem-puppetdb_cli':
    name     => 'puppetdb_cli',
    provider => 'puppet_gem',
  }
  -> file { '/opt/puppetlabs/bin/puppet-query':
    ensure => link,
    target => '/opt/puppetlabs/puppet/bin/puppet-query',
  }
  -> file { '/etc/puppetlabs/client-tools':
    ensure => directory,
  }
  -> file { '/etc/puppetlabs/client-tools/puppetdb.conf':
    mode    => '0640',
    content => stdlib::to_json_pretty(
      {
        puppetdb => {
          server_urls => "https://${facts['networking']['fqdn']}:8081",
          cacert      => "${puppet_confdir}/ssl/certs/ca.pem",
          cert        => "${puppet_confdir}/ssl/certs/${facts['networking']['fqdn']}.pem",
          key         => "${puppet_confdir}/ssl/private_keys/${facts['networking']['fqdn']}.pem",
        },
      }
    ),
  }
}

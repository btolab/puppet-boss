# puppetserver config
#
# @api private
class boss::profile::puppetserver::config {
  $java_mem = ['mx', 'ms'].reduce([]) |$memo, $v| {
    $value = getvar("boss::profile::puppetserver::java_${v}")
    if $value { $memo + ["-X${v}${value}"] } else { $memo }
  }

  $java_args = getvar('boss::profile::puppetserver::java_args')

  augeas { 'puppetserver-environment':
    context => "/files${lookup('boss::path::sysconfig')}/puppetserver",
    changes => [
      "set JAVA_ARGS '\"${java_mem.join(' ')} ${java_args} -Djruby.logger.class=com.puppetlabs.jruby_utils.jruby.Slf4jLogger\"'",
    ],
  }

  package { 'gem-hiera-eyaml':
    name     => 'hiera-eyaml',
    provider => 'puppet_gem',
  }
  -> file { '/opt/puppetlabs/bin/eyaml':
    ensure => link,
    target => '/opt/puppetlabs/puppet/bin/eyaml',
  }

  augeas { 'puppetserver-syslog':
    incl    => '/etc/puppetlabs/puppetserver/logback.xml',
    lens    => 'xml.lns',
    changes => [
      "defnode aref configuration/root/appender-ref[#attribute/ref='SYSLOG'] ''",
      "set \$aref/#attribute/ref 'SYSLOG'",
      "defnode a configuration/appender[#attribute/name='SYSLOG'] ''",
      "set \$a/#attribute/name 'SYSLOG'",
      "set \$a/#attribute/class 'ch.qos.logback.classic.net.SyslogAppender'",
      "set \$a/syslogHost/#text 'localhost'",
      "set \$a/facility/#text 'DAEMON'",
      "set \$a/suffixPattern/#text '%thread: %-5level %logger{36} - %msg%n'",
    ],
  }

  # augeas { 'puppetserver-config-master':
  #   context => "/files${settings::confdir}/puppet.conf",
  #   changes => [
  #   ],
  # }

  $sans_ip = $facts['networking']['interfaces'].reduce([]) |$memo, $i| {
    if !($i[0] =~ '^lo') and $i[1]['mtu'] < 10000 and 'ip' in $i[1] { $memo + ["IP:${i[1]['ip']}"] } else { $memo }
  }
  $sans_dns = ["DNS:puppet.${facts['networking']['domain']}", 'DNS:puppet',]

  $sans = [$sans_ip, $sans_dns].flatten.join(',')

  $common_changes = [
    "set main/dns_alt_names ${sans}",
  ]

  augeas { 'puppet-config-puppetserver-common':
    context => '/files/etc/puppetlabs/puppet/puppet.conf',
    changes => $common_changes,
  }
}

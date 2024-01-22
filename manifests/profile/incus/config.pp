# incus config
#
# @api private
class boss::profile::incus::config {
  $sysctl = $boss::profile::incus::sysctl

  file { '/etc/security/limits.d/incus.conf':
    owner   => 0,
    group   => 0,
    content => @(EOD)
      *    soft nofile  1048576
      *    hard nofile  1048576
      root soft nofile  1048576
      root hard nofile  1048576
      *    soft memlock unlimited
      *    hard memlock unlimited
      root soft memlock unlimited
      root hard memlock unlimited
      | EOD
    ,
  }

  if $sysctl {
    $sysctl.each |$key, $value| {
      sysctl::variable { $key: ensure => $value }
    }
  }
}

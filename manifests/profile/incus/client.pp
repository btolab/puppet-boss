# incus client install
#
# @param ensure
#
class boss::profile::incus::client (
  String $ensure = $boss::profile::incus::ensure,
) {
  realize(Boss::Repository['zabbly'])

  package { 'incus-client':
    ensure  => $ensure,
    require => Boss::Repository['zabbly'],
  }
}

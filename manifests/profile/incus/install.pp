# incus install
#
# @api private
class boss::profile::incus::install {
  realize(Boss::Repository['zabbly'])

  $ensure = $boss::profile::incus::ensure

  if ($ensure != 'absent' and $boss::profile::incus::additional_packages) {
    stdlib::ensure_packages($boss::profile::incus::additional_packages)
  }

  package { 'incus':
    ensure  => $ensure,
    require => Boss::Repository['zabbly'],
  }
}

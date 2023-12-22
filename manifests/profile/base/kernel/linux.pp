# base linux kernel
class boss::profile::base::kernel::linux {
  host { 'primary':
    name         => $facts['networking']['fqdn'],
    ip           => $facts['networking']['ip'],
    host_aliases => [
      $facts['networking']['hostname'],
    ],
  }
  host { 'remove-primary-barehost':
    ensure => absent,
    name   => $facts['networking']['hostname'],
    ip     => $facts['networking']['ip'],
  }
}

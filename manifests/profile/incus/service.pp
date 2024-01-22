# manage incus services
#
# @api private
class boss::profile::incus::service {
  service { 'incus-lxcfs':
    ensure => running,
    enable => true,
  }
  -> service { 'incus':
    ensure => running,
    enable => true,
  }
  -> service { 'incus-user':
    enable => $boss::profile::incus::unprivileged,
  }
}

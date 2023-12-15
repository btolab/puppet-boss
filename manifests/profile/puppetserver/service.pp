# manage puppetserver services
#
# @api private
class boss::profile::puppetserver::service {
  Service <| tag == 'puppetdb' |>
  ~> service { 'puppetserver':
    ensure => running,
    enable => true,
  }
}

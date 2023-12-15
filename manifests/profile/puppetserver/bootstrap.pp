# puppetserver bootstrap
#
# @api private
class boss::profile::puppetserver::bootstrap {
  exec { 'puppetserver-ca-setup':
    command => '/opt/puppetlabs/bin/puppetserver ca setup',
    creates => "/etc/puppetlabs/puppetserver/ca/signed/${facts['networking']['fqdn']}.pem",
  }
  -> Service <| tag == 'puppetdb' |>
}

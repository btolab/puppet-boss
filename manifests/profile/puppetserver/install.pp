# puppetserver install
#
# @api private
class boss::profile::puppetserver::install {
  require boss::profile::openjdk

  package { 'puppetserver':
    ensure => $boss::profile::puppetserver::ensure,
  }
}

# puppetserver install
#
# @api private
class boss::profile::puppetserver::install {
  realize(Boss::Repository['puppet'])

  require boss::profile::openjdk

  Host <| ip == $facts['networking']['ip'] |> {
    host_aliases +> 'puppet',
  }

  # workaround puppetserver pulling in a very old java
  if ($facts['os']['family'] in ['Suse', 'RedHat']) {
    boss::fakeprovide { 'openjdk18':
      provide => 'java-1.8.0-openjdk-headless',
      extras  => ['java-1_8_0-openjdk-headless'],
      before  => Package['puppetserver'],
    }
  }

  package { 'puppetserver':
    ensure => $boss::profile::puppetserver::ensure,
  }
}

# standalone open source puppet server role
class boss::role::puppet::server {
  include boss::profile::base
  include boss::profile::puppetserver
  include boss::profile::puppetdb
}

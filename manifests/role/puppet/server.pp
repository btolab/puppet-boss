# standalone open source puppet server role
class boss::role::puppet::server {
  include boss::profile::base
  include boss::profile::puppetserver
  include boss::profile::puppetdb
  include boss::profile::puppetboard
  include boss::profile::r10k
}

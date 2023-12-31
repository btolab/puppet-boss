# install and configure puppetserver and puppetdb
#
# @param ensure
# @param java_mx
#   set java service Xmx argument to value
# @param java_ms
#   set java service Xmx argument to value
#
class boss::profile::puppetserver (
  String $ensure = 'latest',
  Pattern[/^[0-9]+[kmg]$/] $java_ms = '1g',
  Pattern[/^[0-9]+[kmg]$/] $java_mx = '1g',
) {
  contain "${name}::install"
  contain "${name}::config"
  contain "${name}::bootstrap"
  include "${name}::service"

  Class["${name}::install"]
  -> Class["${name}::config"]
  -> Class["${name}::bootstrap"]
  -> Class["${name}::service"]

  Class["${name}::install"]
  ~> Class["${name}::service"]

  Class["${name}::config"]
  ~> Class["${name}::service"]
}

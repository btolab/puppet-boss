# install and configure puppetserver and puppetdb
#
# @param ensure
# @param java_mx
#   set java service Xmx argument to value
# @param java_ms
#   set java service Xmx argument to value
# @param java_args
#   additional java arguments
#
class boss::profile::puppetserver (
  String $ensure = 'latest',
  Pattern[/^[0-9]+[kmg]$/] $java_ms = '128m',
  Pattern[/^[0-9]+[kmg]$/] $java_mx = '1g',
  Optional[String] $java_args = undef,
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

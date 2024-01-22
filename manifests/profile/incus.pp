# install and configure incus
#
# @param ensure
# @param unprivileged
#   support unprivileged containers through user service
# @param sysctl
# @param additional_packages
#
class boss::profile::incus (
  String $ensure = 'latest',
  Boolean $unprivileged = true,
  Optional[Hash] $sysctl = undef,
  Optional[Array[String]] $additional_packages = undef,
) {
  if $facts['os']['family'] != 'Debian' {
    fail("${facts['os']['family']} not supported")
  }

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

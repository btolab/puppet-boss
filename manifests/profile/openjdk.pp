# install openjdk
#
# @param package_name
#   name of package
# @param ensure
#   version or state of package
#
class boss::profile::openjdk (
  String $package_name,
  String $ensure = 'installed',
) {
  package { $package_name:
    ensure => $ensure,
  }
}

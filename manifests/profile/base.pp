# base node requirements
#
# @param manage_firewall
class boss::profile::base (
  Boolean $manage_firewall = true,
) {
  if $manage_firewall {
    include firewall
  }

  contain "${title}::os"
  contain "${title}::kernel"
}

# base node requirements
#
# @param manage_firewall
# @param manage_sysctl
class boss::profile::base (
  Boolean $manage_firewall = true,
  Boolean $manage_sysctl = true,
) {
  if $manage_firewall {
    include firewall
  }

  if $manage_sysctl {
    include sysctl
  }

  contain "${title}::os"
  contain "${title}::kernel"
}

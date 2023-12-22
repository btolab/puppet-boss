# base node requirements
class boss::profile::base {
  include firewall
  contain "${title}::os"
  contain "${title}::kernel"
}

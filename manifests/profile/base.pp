# base node requirements
class boss::profile::base {
  include firewall
  include "${title}::os"
}

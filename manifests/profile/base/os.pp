# base node requirements
class boss::profile::base::os {
  include "${title}::${facts['os']['family'].downcase()}"
}

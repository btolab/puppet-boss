# base os redhat
class boss::profile::base::os::redhat {
  # set selinux to permissive/disabled for now
  exec { 'selinux-enforce=0':
    command => '/usr/bin/env echo 0 > /sys/fs/selinux/enforce',
    onlyif  => '/usr/bin/env test `cat /sys/fs/selinux/enforce` -eq 1',
  }
}

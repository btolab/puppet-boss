# base kernel
class boss::profile::base::kernel {
  include "${title}::${facts['kernel'].downcase()}"
}

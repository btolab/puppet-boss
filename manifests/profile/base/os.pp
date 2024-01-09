# base node requirements
#
# @param packages
# @param repos
class boss::profile::base::os (
  Array $packages = [],
  Hash $repos = {},
) {
  stdlib::ensure_packages($packages)

  $repos.each |$repo, $params| {
    @Resource["boss::repository::${facts['package_provider']}"] { $repo:
      * => $params,
    }

    if $params['realize'] {
      realize(Boss::Repository::Apt[$repo])
    }
  }

  include "${title}::${facts['os']['family'].downcase()}"
}

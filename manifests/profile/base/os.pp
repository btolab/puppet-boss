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
    @boss::repository { $repo:
      params   => $params,
      provider => $facts['package_provider'],
    }

    if $params['realize'] {
      realize(Boss::Repository[$repo])
    }
  }

  include "${title}::${facts['os']['family'].downcase()}"
}

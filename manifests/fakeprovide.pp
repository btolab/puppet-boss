# fakeprovide rpm dependency
#
# @param provide
#   what to provide
# @param extra
#   extra provides to add to package
define boss::fakeprovide (
  String $provide = $title,
  Optional[Array[String]] $extras = undef,
) {
  if $extras {
    $extra_provides = "-P '${extras.join(' ')}'"
  }

  $package_version = fqdn_rand(8192, md5("${provide}+${extra_provides}"))
  $package_name = "fakeprovide-${provide}-${package_version}-1"

  $required_packages = lookup('boss::fakeprovide::packages', Variant[Array[String],String], undef, 'rpm-build')
  stdlib::ensure_packages($required_packages)

  ensure_resource('file', '/usr/bin/fakeprovide', {
    mode    => '0755',
    content => file('boss/profile/fakeprovide'),
    require => Package[$required_packages],
  })

  exec { "build-fakeprovide-${title}":
    command => "/usr/bin/fakeprovide -v ${package_version} ${extra_provides} ${provide}",
    cwd     => "/var/tmp",
    creates => [
      "/var/tmp/${package_name}.el${facts['os']['release']['major']}.noarch.rpm",
      "/var/tmp/${package_name}.noarch.rpm",
    ],
    require => File['/usr/bin/fakeprovide'],
  }
  ~> exec { "install-fakeprovide-${title}":
    command => "/usr/bin/env rpm -Uvh --force --oldpackage /var/tmp/${package_name}.*noarch.rpm",
    unless  => "/usr/bin/env rpm -q ${package_name}"
  }
}

# fake provide rpm dependencies
#
# @param provide
#   what to provide
# @param extras
#   extra provides to add to package
#
# @example
#   fakeprovide { 'openjdk18':
#     provide => 'java-1.8.0-openjdk-headless',
#     extras  => ['java-1_8_0-openjdk-headless'],
#     before  => Package['puppetserver'],
#   }
define boss::fakeprovide (
  Pattern[/[A-Za-z0-9._\-+]+/] $provide = $title,
  Optional[Array[Pattern[/[A-Za-z0-9._\-+]+/]]] $extras = undef,
) {
  $fakeprovide = '/usr/local/bin/fakeprovide'
  $required_packages = ['rpm-build']

  if $extras { $extra_provides = "-P '${extras.join(' ')}'" }

  $package_version = fqdn_rand(8192, md5("${provide}+${extra_provides}"))
  $package_name = "fakeprovide-${provide}-${package_version}"

  stdlib::ensure_packages($required_packages)

  if !defined(File[$fakeprovide]) {
    file { $fakeprovide:
      mode    => '0755',
      source  => "puppet:///modules/${module_name}/fakeprovide",
      require => Package[$required_packages],
    }
  }

  exec { "fakeprovide-build-${title}":
    command => "${fakeprovide} -v ${package_version} ${extra_provides} ${provide}",
    cwd     => '/var/tmp',
    creates => [
      "/var/tmp/${package_name}.el${facts['os']['release']['major']}.noarch.rpm",
      "/var/tmp/${package_name}.noarch.rpm",
    ],
    unless  => "/usr/bin/env rpm -q ${package_name}",
    require => File[$fakeprovide],
  }
  ~> exec { "fakeprovide-install-${title}":
    command => "/usr/bin/env rpm -Uvh --force --oldpackage /var/tmp/${package_name}-*noarch.rpm",
    unless  => "/usr/bin/env rpm -q ${package_name}",
  }
}

# puppet r10k
#
# @param sources
# @param rugged_build_packages
# @param cachedir
#
class boss::profile::r10k (
  Boss::R10k::Sources  $sources,
  Array[String]        $rugged_build_packages,
  Stdlib::Absolutepath $cachedir = '/var/cache/r10k',
) {
  if $facts['os']['family'] == 'RedHat' {
    include epel
    Yumrepo <| tag == 'epel' |> -> Package[$rugged_build_packages]
  }

  stdlib::ensure_packages($rugged_build_packages)

  $r10k_sources = $sources.reduce({}) |$memo, $v| {
    $memo + {
      $v[0] => $v[1].filter |$p| {
        $p[0] =~ /(remote|basedir)/
      }
    }
  }

  $r10k_repositories = $sources.map |$v| {
    $v[1].reduce({}) |$memo, $p| {
      if $p[0] =~ /(private_key|oauth_token)/ {
        $checksum = md5($p[1])
        $file_name = "/etc/puppetlabs/r10k/${p[0]}-${checksum}"

        file { $file_name:
          mode    => '0600',
          owner   => 'puppet',
          group   => 'puppet',
          content => Sensitive($p[1]),
        }

        $memo + { $p[0] => $file_name }
      } elsif $p[0] == 'remote' {
        $parsed = boss::url_parse($p[1])
        if $parsed['host'] {
          exec { "ssh-keyscan-${v[0]}":
            path    => ['/usr/bin', '/bin'],
            command => "mkdir -p .ssh && ssh-keyscan ${parsed['host']} >> .ssh/known_hosts",
            unless  => "ssh-keygen -F ${parsed['host']}",
          }
        }

        $memo + { $p[0] => $p[1] }
      } else {
        $memo
      }
    }
  }

  package { 'gem-rugged':
    name            => 'rugged',
    provider        => 'puppet_gem',
    # install_options are not appended to the provider command so we can't
    # just pass the --with-ssh argument through to make :(
    # here be dragons...
    install_options => ['--no-document', 'rugged', '--', '--with-ssh'],
    require         => Package[$rugged_build_packages],
  }
  -> package { 'gem-r10k':
    name     => 'r10k',
    provider => 'puppet_gem',
  }
  -> file { '/opt/puppetlabs/bin/r10k':
    ensure => link,
    target => '/opt/puppetlabs/puppet/bin/r10k',
  }
  -> file { '/etc/puppetlabs/r10k':
    ensure  => directory,
    mode    => '0750',
    owner   => 'puppet',
    group   => 'puppet',
    purge   => true,
    recurse => true,
  }
  -> file { '/etc/puppetlabs/r10k/r10k.yaml':
    owner   => 'puppet',
    group   => 'puppet',
    content => epp("${module_name}/profile/r10k.yaml.epp", {
        cachedir     => $cachedir,
        sources      => $r10k_sources,
        repositories => $r10k_repositories,
    }),
  }

  file { $cachedir:
    ensure => directory,
    owner  => 'puppet',
    group  => 'puppet',
    mode   => '0750',
  }
}

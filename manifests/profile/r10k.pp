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
  require boss::profile::puppetserver::install

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

  # pin older gems for ruby 2.7
  if $facts['puppetversion'] =~ /^7/ {
    package { 'gem-faraday':
      ensure   => '2.8.1',
      name     => 'faraday',
      provider => 'puppet_gem',
    }
    -> package { 'gem-faraday-net_http':
      ensure   => '3.0.2',
      name     => 'faraday-net_http',
      provider => 'puppet_gem',
      before   => Package['gem-r10k'],
    }
  }

  # all of this for r10k ssh support
  # build r10k dependencies inside aio puppet
  archive { '/var/tmp/libssh2-1.11.0.tar.gz':
    source        => 'https://libssh2.org/download/libssh2-1.11.0.tar.gz',
    checksum_type => 'sha256',
    checksum      => '3736161e41e2693324deb38c26cfdc3efe6209d634ba4258db1cecff6a5ad461',
    cleanup       => true,
    creates       => '/var/tmp/libssh2-1.11.0',
    extract       => true,
    extract_path  => '/var/tmp',
  }
  ~> exec { 'puppet-libssh2':
    path        => ['/opt/puppetlabs/puppet/bin', '/usr/bin', '/bin'],
    command     => 'mkdir -p /var/tmp/puppet-build ; cd /var/tmp/puppet-build && rm -rf * && cmake /var/tmp/libssh2-1.11.0 -DCMAKE_INSTALL_PREFIX=/opt/puppetlabs/puppet -DCMAKE_PREFIX_PATH=/opt/puppetlabs/puppet -DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_INSTALL_RPATH=/opt/puppetlabs/puppet/lib -DENABLE_ZLIB_COMPRESSION=ON && make -j install && cd .. && rm -rf puppet-build',
    refreshonly => true,
    require     => Package[$rugged_build_packages],
  }
  -> archive { '/var/tmp/libgit2-1.7.1.tar.gz':
    source        => 'https://github.com/libgit2/libgit2/archive/refs/tags/v1.7.1.tar.gz',
    checksum_type => 'sha256',
    checksum      => '17d2b292f21be3892b704dddff29327b3564f96099a1c53b00edc23160c71327',
    cleanup       => true,
    creates       => '/var/tmp/libgit2-1.7.1',
    extract       => true,
    extract_path  => '/var/tmp',
  }
  ~> exec { 'puppet-libgit2':
    path        => ['/opt/puppetlabs/puppet/bin', '/usr/bin', '/bin'],
    command     => 'mkdir -p /var/tmp/puppet-build ; cd /var/tmp/puppet-build && rm -rf * && cmake /var/tmp/libgit2-1.7.1 -DCMAKE_INSTALL_PREFIX=/opt/puppetlabs/puppet -DCMAKE_PREFIX_PATH=/opt/puppetlabs/puppet -DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_INSTALL_RPATH=/opt/puppetlabs/puppet/lib -DUSE_SSH=ON -DUSE_HTTPS=OpenSSL-Dynamic && make -j install && cd .. && rm -rf puppet-build',
    refreshonly => true,
  }
  -> package { 'gem-rugged':
    name            => 'rugged',
    provider        => 'puppet_gem',
    # install_options are not appended to the provider command so we can't
    # just pass the --with-ssh argument through to make :(
    # here be dragons...
    install_options => ['--no-document', 'rugged', '--', '--with-ssh', '--use-system-libraries'],
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

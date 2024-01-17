# @summary apt source
#
# Manage apt package source
#
# @param ensure
#   state of resource
# @param url
#   apt source url
# @param list
#   name of list file (without .list)
# @param key
#   gpg id and server to lookup key
# @param key_url
#   gpg key url
# @param key_checksum
#   supply to prevent checking if the remote file has changed
# @param key_path
#   where to store keyrings (must exist)
# @param distro
# @param release
# @param armor
#   should the key be de-armored?
# @param flags
# @param realize
#   not used by referenced externally
#
define boss::repository::apt (
  Stdlib::HTTPUrl           $url,
  Enum['absent','present']  $ensure = 'present',
  String                    $list = $title,
  Optional[Array]           $key = undef,
  Optional[Stdlib::HTTPUrl] $key_url = undef,
  Optional[String]          $key_checksum = undef,
  Stdlib::Absolutepath      $key_path = '/usr/share/keyrings',
  String                    $distro = $facts['os']['distro']['codename'],
  String                    $release = 'main',
  Boolean                   $armor = false,
  Optional[Hash]            $flags = undef,
  Boolean                   $realize = ($ensure == 'absent'),
) {
  $list_path = "/etc/apt/sources.list.d/${list}.list"
  $list_line = "apt-sources-list-${title}"

  # hack hiera value with a function (downcase)
  $final_url = ($url =~ /(.*):(\w+)\(\)$/) ? {
    true  => Deferred($2, [$1]).call(),
    false => $url,
  }

  $final_key_url = ($key_url =~ /(.*):(\w+)\(\)$/) ? {
    true  => Deferred($2, [$1]).call(),
    false => $key_url,
  }

  if $final_key_url {
    $gpg_filename = $armor ? {
      true    => "${key_path}/${title}.armor.gpg",
      default => "${key_path}/${title}.gpg",
    }

    if $ensure != 'absent' {
      file { $gpg_filename:
        ensure         => file,
        path           => $gpg_filename,
        source         => $final_key_url,
        checksum       => ($key_checksum =~ String) ? {
          true  => 'sha256',
          false => undef,
        },
        checksum_value => $key_checksum,
        notify         => Exec["repo-update-${title}"],
        before         => File_line[$list_line],
      }
      -> exec { "dearmor-gpgkey-${title}":
        command     => "/usr/bin/env gpg --dearmor < ${gpg_filename} > ${key_path}/${title}.gpg",
        require     => Package['gpg'],
        notify      => Exec["repo-update-${title}"],
        before      => File_line[$list_line],
        subscribe   => ($armor) ? {
          true  => File[$gpg_filename],
          false => undef,
        },
        refreshonly => true,
      }
    }

    $signed_by = "signed-by=${key_path}/${title}.gpg"
    $repo_flags = sprintf('[%s] ', ($flags) ? {
        true    => $flags.reduce([$signed_by]) |$memo, $value| { $memo + sprintf('%s=%s', $value[0], $value[1]) }.join(' '),
        default => $signed_by,
    })
  } else {
    # TODO deprecated and does'nt work with multi source lists
    if $ensure != 'absent' and $key {
      apt::key { $title:
        id     => $key[1],
        server => $key[0],
        notify => Exec["repo-update-${title}"],
        before => File_line[$list_line],
      }
    }
    $repo_flags = ''
  }

  if $ensure == 'present' {
    ensure_resource('file', $list_path, {
        ensure => present,
        owner  => 0,
        group  => 0,
        mode   => '0644',
    })
    ensure_resource('file_line', $list_path, {
        path => $list_path,
        line => '# Managed by Puppet',
    })
  }

  file_line { $list_line:
    ensure            => $ensure,
    path              => $list_path,
    match             => sprintf('^deb .*%s %s %s', $final_url, $distro, $release),
    line              => sprintf('deb %s%s %s %s', $repo_flags, $final_url, $distro, $release),
    match_for_absence => true,
  }
  ~> exec { "repo-update-${title}":
    command     => '/usr/bin/env apt-get -d update',
    require     => Package['ca-certificates'],
    refreshonly => true,
  }
}

# @summary yum repo
#
# Manage yum package repo
#
# @param url
#   base url
# @param ensure
# @param description
# @param key_url
#   gpg key url
# @param key_checksum
#   supply to prevent checking if the remote file has changed
# @param key_path
#   where to store key (must exist)
# @param realize
#   not used by referenced externally
#
define boss::repository::yum (
  Stdlib::HTTPUrl           $url,
  Enum['absent','present']  $ensure = 'present',
  String                    $description = $title,
  Optional[Stdlib::HTTPUrl] $key_url = undef,
  Optional[String]          $key_checksum = undef,
  Stdlib::Absolutepath      $key_path = '/etc/pki/rpm-gpg',
  Boolean                   $realize = ($ensure == 'absent'),
) {
  # hack hiera value with a function (downcase)
  $final_url = ($url =~ /(.*):(\w+)\(\)$/) ? {
    true  => Deferred($2, [$1]).call(),
    false => $url,
  }

  $final_key_url = ($key_url =~ /(.*):(\w+)\(\)$/) ? {
    true  => Deferred($2, [$1]).call(),
    false => $key_url,
  }

  $file_ensure = $ensure ? {
    'present' => 'file',
    default   => 'absent',
  }
  $yumrepo_enabled = $ensure ? {
    'present' => true,
    default   => false,
  }

  if $final_key_url {
    $gpg_filename = "${key_path}/${title}.gpg"

    file { $gpg_filename:
      ensure         => $file_ensure,
      path           => $gpg_filename,
      source         => $final_key_url,
      checksum       => ($key_checksum =~ String) ? {
        true  => 'sha256',
        false => undef,
      },
      checksum_value => $key_checksum,
      before         => Yumrepo[$title],
    }
  }

  yumrepo { $title:
    enabled  => $yumrepo_enabled,
    baseurl  => $final_url,
    descr    => $description,
    gpgkey   => ($gpg_filename) ? {
      /.+/    => "file://${gpg_filename}",
      default => '0',
    },
    gpgcheck => ($gpg_filename) ? {
      /.+/    => '1',
      default => '0',
    },
  }
}

# manage system python
#
# @param version
#
class boss::profile::python (
  String $version = '3',
  Boolean $manage_pip_package = false,
  Optional[Boolean] $manage_venv_package = undef,
) {
  $_version = regsubst($version, '^(\d+)\.?(\d+)?.*', '\1\2')

  class { 'python':
    version             => $_version,
    dev                 => 'present',
    venv                => 'present',
    manage_gunicorn     => false,
    manage_pip_package  => $manage_pip_package,
    manage_venv_package => $manage_venv_package,
  }
}

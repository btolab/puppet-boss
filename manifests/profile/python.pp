# manage system python
#
# @param version
#   pass-through parameter for the python module
# @param manage_pip_package
#   installing a system pip is generally discouraged
# @param manage_venv_package
#   if venv support is bundled with python, set to false in hiera
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

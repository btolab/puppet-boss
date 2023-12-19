# manage system python
#
# @param version
#
class boss::profile::python (
  String $version = '3',
) {
  $_version = regsubst($version, '^(\d+)\.?(\d+)?.*', '\1\2')

  class { 'python':
    version         => $_version,
    pip             => 'present',
    dev             => 'present',
    venv            => 'present',
    manage_gunicorn => false,
  }

  # work-around python module unable to manage the gunicorn package
  # without managing some weird debian specific service framework
  package { 'gunicorn':
    name => $python::gunicorn_package_name,
  }

  Yumrepo <| tag == 'epel' |> -> Package['gunicorn']
}

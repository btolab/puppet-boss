# manage system python
#
class boss::profile::python {
  class { 'python':
    version         => '3',
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
}

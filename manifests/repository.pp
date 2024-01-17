# @summary boss repository
#
# wrapper for provider types
define boss::repository (
  Enum['apt', 'yum'] $provider,
  Hash $params,
) {
  if $provider == 'apt' {
    @boss::repository::apt { $title:
      * => $params,
    }
  } else {
    fail('not implemented')
  }

  Boss::Repository::Apt <| |> -> Package <| title != 'gpg' and title != 'ca-certificates' |>
}

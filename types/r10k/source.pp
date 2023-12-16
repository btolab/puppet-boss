# @summary r10k source
#
# @param remote
# @param basedir
# @param private_key
# @param oath_token
# @param prefix
# @param puppet_filename
#
type Boss::R10k::Source = Struct[{
    remote          => Boss::Url::Git,
    basedir         => Optional[Stdlib::Absolutepath],
    private_key     => Optional[Pattern[/^(?m:-----BEGIN (DSA|EC|OPENSSH|RSA) PRIVATE KEY-----.*-----END \1 PRIVATE KEY-----)/]],
    oauth_token     => Optional[String],
    prefix          => Optional[Boolean],
    puppet_filename => Optional[String],
}]

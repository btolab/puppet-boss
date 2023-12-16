# @summary Validate a Git URL
type Boss::Url::Git = Pattern[/((git|ssh|http(s)?)|(git@[\w\.]+))(:(\/\/)?)([\w\.@\:\/\-~]+)(\.git)(\/)?/]

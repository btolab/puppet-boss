# frozen_string_literal: true

require 'uri'

Puppet::Functions.create_function(:'boss::url_parse', Puppet::Functions::InternalFunction) do
  # @param value
  #   value to parse URL
  #
  # @return
  #   hash of URL parts
  #
  # @example
  #   $test = 'https://my_user:my_pass@www.example.com:8080/path/to/file.php?id=1&ret=0'
  #   $parsed = boss::url_parse($test)
  #
  #   Returned value:
  #   {
  #     scheme => 'https',
  #     userinfo => 'my_user:my_pass',
  #     user => 'my_user',
  #     password => 'my_pass',
  #     host => 'www.example.com',
  #     port => '8080',
  #     path => '/path/to/file.php',
  #     query => 'id=1&ret=0',
  #   }
  #
  dispatch :url_parse do
    required_param 'String', :value
    return_type 'Hash'
  end

  def url_parse(value)
    begin
      parsed = URI.parse(value)
    rescue URI::InvalidURIError
      host_part, path_part = value.split(':', 2)
      # There may be no user, so reverse the split to make sure host always
      # is !nil if host_part was !nil.
      host, userinfo = host_part.split('@', 2).reverse
      parsed = URI::Generic.build(userinfo: userinfo, host: host, path: path_part)
    end

    Hash[['scheme', 'userinfo', 'user', 'password', 'host', 'port', 'path', 'query'].map { |var|
      val = parsed.send(var)
      (val.nil? || val.to_s.empty?) ? nil : [ var, val ]
    }.compact]
  end
end

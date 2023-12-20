# frozen_string_literal: true

include RspecPuppetFacts

# Usage
#
# let(:facts) do
#   override_facts(super(), os: {'selinux' => {'enabled' => false}})
# end
def override_facts(base_facts, **overrides)
  facts = Marshal.load(Marshal.dump(base_facts))
  apply_overrides!(facts, overrides, true)
  facts
end

# A private helper to override_facts
def apply_overrides!(facts, overrides, enforce_strings)
  overrides.each do |key, value|
    # Nested facts are strings
    key = key.to_s if enforce_strings

    if value.is_a?(Hash)
      facts[key] = {} unless facts.key?(key)
      apply_overrides!(facts[key], value, true)
    else
      facts[key] = value
    end
  end
end

def add_stdlib_facts
  add_custom_fact :puppet_environmentpath, '/etc/puppetlabs/code/environments'
  add_custom_fact :puppet_vardir, '/opt/puppetlabs/puppet/cache'
  add_custom_fact :root_home, '/root'

  # Rough conversion of grepping in the puppet source:
  # grep defaultfor lib/puppet/provider/service/*.rb
  add_custom_fact :service_provider, ->(_, facts) do
    case facts[:os]['family'].downcase
    when 'archlinux'
      'systemd'
    when 'darwin'
      'launchd'
    when 'debian'
      if facts[:os]['name'].casecmp('ubuntu').zero?
        (facts[:os]['release']['major'].to_i > 14) ? 'systemd' : 'upstart'
      else
        (facts[:os]['release']['major'].to_i >= 8) ? 'systemd' : 'init'
      end
    when 'freebsd'
      'freebsd'
    when 'gentoo'
      'openrc'
    when 'openbsd'
      'openbsd'
    when 'redhat'
      (facts[:os]['release']['major'].to_i >= 7) ? 'systemd' : 'redhat'
    when 'suse'
      (facts[:os]['release']['major'].to_i >= 12) ? 'systemd' : 'redhat'
    when 'windows'
      'windows'
    else
      'init'
    end
  end
end

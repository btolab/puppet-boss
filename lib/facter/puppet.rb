# Fact: puppet
#
# Purpose: structured information about the puppet agent
#
Facter.add(:puppet) do
  setcode do
    found_version = Facter.value('pe_build') || Facter.value('puppetversion') || Facter.value('aio_puppet_version')
    if found_version
      ver = found_version.match(%r{((\d+)\.(\d+)\.(\d+))})
      found_version = {
        full: ver[1],
        major: ver[2].to_i,
        minor: ver[3].to_i,
        patch: ver[4].to_i,
      }
    end

    found_version
  end
end

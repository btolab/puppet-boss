include RspecPuppetFacts

require 'puppet-catalog_rspec' if Bundler.rubygems.find_name('puppet-catalog_rspec').any?

Dir['./spec/support/unit/**/*.rb'].sort.each { |f| require f }

RSpec.configure do |c|
  c.facterdb_string_keys = true
  c.silence_filter_announcements = true
  c.hiera_config = File.expand_path(File.join(__FILE__, '../fixtures/hiera.yaml'))

  # Prevent rspec dumping a full backtrace on coverage failure
  c.backtrace_inclusion_patterns = [ %r{in `<main>'} ]
end

def with_captured_stdout
  o_stdout = $stdout
  $stdout = StringIO.new
  yield
  $stdout.string
ensure
  $stdout = o_stdout
end

add_stdlib_facts

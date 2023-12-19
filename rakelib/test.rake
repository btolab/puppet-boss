require 'metadata_json_lint'

# Colorize Strings
class String
  def black;          "\e[30m#{self}\e[0m" end
  def red;            "\e[31m#{self}\e[0m" end
  def green;          "\e[32m#{self}\e[0m" end
  def brown;          "\e[33m#{self}\e[0m" end
  def blue;           "\e[34m#{self}\e[0m" end
  def magenta;        "\e[35m#{self}\e[0m" end
  def cyan;           "\e[36m#{self}\e[0m" end
  def gray;           "\e[37m#{self}\e[0m" end

  def bold;           "\e[1m#{self}\e[22m" end
  def italic;         "\e[3m#{self}\e[23m" end
  def underline;      "\e[4m#{self}\e[24m" end
  def blink;          "\e[5m#{self}\e[25m" end
  def reverse_color;  "\e[7m#{self}\e[27m" end
end

# Replicates PDK validate behavior.
MetadataJsonLint.options.fail_on_warnings = true
MetadataJsonLint.options.strict_license = true
MetadataJsonLint.options.strict_puppet_version = true
MetadataJsonLint.options.strict_dependencies = true

desc 'Run all tests EXCEPT acceptance'
task test: ['test:check', 'test:syntax', 'test:lint', 'test:doc', 'test:unit']

namespace :test do
  desc 'Run static pre-release checks'
  task check: [:check]

  desc 'Run syntax checks'
  task syntax: [:syntax]

  desc 'Run linters'
  task lint: [:lint, :metadata_lint, :rubocop]

  desc 'Run documentation tests'
  task doc: ['strings:validate:reference']

  desc 'Run all unit tests in parallel'
  task unit: [:parallel_spec]

  desc 'Run acceptance tests'
  task acceptance: [:acceptance]
end

PuppetLint.configuration.log_forat = '%{path}:%{line}:%{check}:%{KIND}:%{message}'
PuppetLint.configuration.fail_on_warnings = true

# output task execution
# exclude test wrapper classes
output_task_header = Regexp.union(
  [ %r{^((?!test))} ],
)

unless Rake.application.options.trace
  setup = ->(task, *_args) do
    puts '=> execute task: '.cyan + task.to_s.bold.cyan
  end

  task :log_hooker do
    Rake::Task.tasks.select { |t| t.to_s != 'log_hooker' && t.to_s =~ output_task_header }.each do |a_task|
      a_task.actions.prepend(setup)
    end
  end
  Rake.application.top_level_tasks.prepend(:log_hooker)
end

# frozen_string_literal: true

litmus_cleanup = false
at_exit { Rake::Task['litmus:tear_down'].invoke if litmus_cleanup }

desc "Provision machines, run acceptance tests, and tear down\n(defaults: key=default, tag=nil)"
task :acceptance, [:key, :tag] do |_task, args|
  args.with_defaults(key: 'default', tag: nil)
  Rake::Task['spec_prep'].invoke
  Rake::Task['litmus:provision_list'].invoke args[:key]
  Rake::Task['litmus:install_agent'].invoke
  Rake::Task['litmus:install_modules_from_fixtures'].invoke
  begin
    Rake::Task['litmus:acceptance:parallel'].invoke args[:tag]
  rescue SystemExit
    litmus_cleanup = false if ENV.fetch('LITMUS_teardown', '').casecmp('auto').zero?
    raise
  end
end

namespace :litmus do
  desc "Run tests against all machines in the inventory file\n(defaults: tag=nil)"
  task :acceptance, [:tag] do |_task, args|
    args.with_defaults(tag: nil)

    Rake::Task.tasks.select { |t| t.to_s =~ %r{^litmus:acceptance:(?!(localhost|parallel)$)} }.each do |litmus_task|
      puts "Running task #{litmus_task}"
      litmus_task.invoke(*args)
    end
  end

  desc "install all fixture modules\n(defaults: resolve_dependencies=false)"
  task :install_modules_from_fixtures, [:resolve_dependencies] do |_task, args|
    args.with_defaults(resolve_dependencies: false)

    Rake::Task['spec_prep'].invoke
    Rake::Task['litmus:install_modules_from_directory'].invoke(nil, nil, nil, !args[:resolve_dependencies])
  end
end

Rake::Task['litmus:provision'].enhance do
  litmus_cleanup = ENV.fetch('LITMUS_teardown', 'true').downcase.match?(%r{(true|auto)})
end
Rake::Task['litmus:provision_list'].enhance do
  litmus_cleanup = ENV.fetch('LITMUS_teardown', 'true').downcase.match?(%r{(true|auto)})
end

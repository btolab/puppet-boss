# frozen_string_literal: true

litmus_cleanup = false
at_exit { Rake::Task['litmus:tear_down'].invoke if litmus_cleanup }

desc "Provision machines, run acceptance tests, and tear down\n(defaults: group=default, tag=nil)"
task :acceptance, [:group, :tag] do |_task, args|
  args.with_defaults(group: 'default', tag: nil)
  Rake::Task['spec_prep'].invoke
  Rake::Task['litmus:provision_list'].invoke args[:group]
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

# Patch docker targets in inventory to support DOCKER_HOST environment variable
task :patch_docker_inventory do
  require 'yaml'
  require 'uri'

  hostname = (ENV['DOCKER_HOST'].nil? || ENV['DOCKER_HOST'].empty?) ? 'localhost' : URI.parse(ENV['DOCKER_HOST']).host || ENV['DOCKER_HOST']
  begin
    docker_context = JSON.parse(run_local_command('docker context inspect'))[0]
    docker_uri = URI.parse(docker_context['Endpoints']['docker']['Host'])
    hostname = docker_uri.host unless docker_uri.host.nil? || docker_uri.host.empty?
  rescue RuntimeError
    # old clients
  end

  if hostname != 'localhost'
    inventory_fn = "#{__dir__}/../spec/fixtures/litmus_inventory.yaml"
    data = YAML.load_file(inventory_fn)
    data['groups'].map do |group|
      next unless !group['targets'].empty?
      group['targets'].map do |target|
        target['uri'].gsub!('localhost', hostname) if target['facts']['provisioner'] == 'docker' && target['uri'] =~ %r{^localhost:}
      end
    end
    File.open(inventory_fn, 'w') { |f| f.write(data.to_yaml) }
  end
end

Rake::Task['litmus:provision'].enhance do
  litmus_cleanup = ENV.fetch('LITMUS_teardown', 'true').downcase.match?(%r{(true|auto)})
  Rake::Task['patch_docker_inventory'].execute
end
Rake::Task['litmus:provision_list'].enhance do
  litmus_cleanup = ENV.fetch('LITMUS_teardown', 'true').downcase.match?(%r{(true|auto)})
  Rake::Task['patch_docker_inventory'].execute
end

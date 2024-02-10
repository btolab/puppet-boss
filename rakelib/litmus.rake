# frozen_string_literal: true

litmus_cleanup = false
at_exit { Rake::Task['litmus:tear_down'].invoke if litmus_cleanup }

desc "Provision machines, run acceptance tests, and tear down\n(defaults: group=default, tag=nil)"
task :acceptance, [:group, :tag] do |_task, args|
  args.with_defaults(group: 'default', tag: nil)
  Rake::Task['spec_prep'].invoke
  litmus_cleanup = ENV.fetch('LITMUS_teardown', 'true').downcase.match?(%r{(true|auto)})
  Rake::Task['litmus:provision_list'].invoke args[:group]
  Rake::Task['litmus:install_agent'].invoke
  Rake::Task['litmus:install_modules'].invoke
  begin
    Rake::Task['litmus:acceptance:parallel'].invoke args[:tag]
  rescue SystemExit
    litmus_cleanup = false if ENV.fetch('LITMUS_teardown', '').casecmp('auto').zero?
    raise
  end
end

Rake::Task['litmus:install_module'].clear
namespace :litmus do
  desc "Run tests against all nodes in the litmus inventory\n(defaults: tag=nil)"
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

  # Install the puppet module under test on a collection of nodes
  #
  # @param :target_node_name [Array] nodes on which to install a puppet module for testing.
  desc 'build the module under test and install it onto targets'
  task :install_module, [:target_node_name, :module_repository, :ignore_dependencies] do |_task, args|
    args.with_defaults(target_node_name: nil, module_repository: nil, ignore_dependencies: false)
    inventory_hash = inventory_hash_from_inventory_file
    target_nodes = find_targets(inventory_hash, args[:target_node_name])
    if target_nodes.empty?
      puts 'No targets found'
      exit 0
    end

    module_tar = build_module
    puts "Built '#{module_tar}'"

    raise "Unable to find package in 'pkg/*.tar.gz'" if module_tar.nil?

    install_module(inventory_hash, args[:target_node_name], module_tar, args[:module_repository], args[:ignore_dependencies])

    puts "Installed '#{module_tar}' on #{args[:target_node_name]}"
  end
end

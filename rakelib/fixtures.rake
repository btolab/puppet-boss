# frozen_string_literal: true

# Create fixture symlink for all bolt project modules

# Returns fixture symlinks hash in the same format as
# PuppetlabsSpecHelper::Tasks::FixtureHelpers
def bolt_fixture_symlinks
  @bolt_fixture_symlinks ||= Dir.glob('.modules/*').select { |f| File.directory? f }.to_h do |d|
    [
      File.realpath(d),
      { 'target' => "spec/fixtures/modules/#{File.basename(d)}" },
    ]
  end

  @bolt_fixture_symlinks
end

task :spec_prep_bolt_modules do
  bolt_fixture_symlinks.each do |target, link|
    setup_symlink(target, link)
  end
end

task :spec_clean_bolt_symlinks do
  bolt_fixture_symlinks.each do |_source, opts|
    target = opts['target']
    FileUtils.rm_f(target)
  end
end

Rake::Task['spec_prep'].enhance do
  Rake::Task['spec_prep_bolt_modules'].invoke
end

Rake::Task['spec_clean_symlinks'].enhance do
  Rake::Task['spec_clean_bolt_symlinks'].invoke
end

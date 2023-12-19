# frozen_string_literal: true

if Bundler.rubygems.find_name('puppet_litmus').any?
  require 'puppet_litmus'

  PuppetLitmus.configure!
end

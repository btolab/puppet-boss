# frozen_string_literal: true

Dir['./spec/support/acceptance/**/*.rb'].sort.each { |f| require f }

RSpec.configure do |c|
  c.fail_fast = true
end

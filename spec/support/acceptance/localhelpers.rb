# frozen_string_literal: true

# module LocalHelpers
# end

RSpec::Matchers.define(:be_one_of) do |expected|
  match do |actual|
    expected.include?(actual)
  end

  failure_message do |actual|
    "expected one of #{expected}, got #{actual}"
  end
end

# RSpec.configure do |c|
#   c.include ::LocalHelpers
# end

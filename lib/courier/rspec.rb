require 'rspec/core'

RSpec::Matchers.define :be_a_twirp_error do |code, msg = nil|
  match do |actual|
    actual.is_a?(Twirp::Error) &&
      (actual.code == code) &&
      (msg.nil? || msg == actual.msg)
  end

  failure_message do |actual|
    if msg
      "expected #{actual.inspect} to be a #{code} error with message #{msg.inspect}"
    else
      "expected #{actual.inspect} to be a #{code} error"
    end
  end
end

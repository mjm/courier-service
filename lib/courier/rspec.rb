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

RSpec.shared_examples 'an unauthenticated request' do
  context 'when no auth token is provided' do
    let(:env) { {} }

    it 'returns an unauthenticated response' do
      expect(response).to be_a_twirp_error :unauthenticated
    end
  end
end

RSpec.shared_examples 'a request from another user' do
  context 'when an auth token from a different user is provided' do
    let(:env) { { token: other_token } }

    it 'returns a forbidden response' do
      expect(response).to be_a_twirp_error :permission_denied
    end
  end
end

module Courier
  module RPCHelpers
    def rpc_method(name)
      let(:method_name) { name }
      let(:response) { subject.call_rpc(method_name, request, env) }
    end

    def self.extend_object(base)
      super
      base.let(:request) { {} }
      base.let(:token) do
        Courier::Middleware::JWTToken.new('sub' => 'example', 'uid' => 123)
      end
      base.let(:other_token) do
        Courier::Middleware::JWTToken.new('sub' => 'example2', 'uid' => 124)
      end
      base.let(:env) { { token: token } }
    end
  end
end

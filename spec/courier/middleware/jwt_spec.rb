require 'rack/test'

RSpec.describe Courier::Middleware::JWT do
  include Rack::Test::Methods

  class TestApp
    def call(_env)
      [200, {}, ['Hello World!']]
    end
  end

  let(:secret) { 'foobar' }
  let(:base_app) { TestApp.new }
  let(:wrapped_app) { described_class.new(base_app, secret: secret) }
  let(:app) { Rack::Lint.new(wrapped_app) }

  shared_examples 'a normal request' do
    it 'falls through to the app response' do
      expect(last_response.body).to eq 'Hello World!'
    end

    it 'does not put a token payload in the Rack environment' do
      expect(last_request.env).not_to have_key 'jwt.payload'
    end

    it 'does not put a token object in the Rack environment' do
      expect(last_request.env).not_to have_key 'jwt.token'
    end
  end

  context 'when no Authorization header is provided' do
    before do
      get '/'
    end

    it_behaves_like 'a normal request'
  end

  context 'when a non-Bearer Authorization header is provided' do
    before do
      header 'Authorization', 'Basic foo:bar'
      get '/'
    end

    it_behaves_like 'a normal request'
  end

  context 'when an invalid token is provided' do
    let(:token) { JWT.encode({}, 'foooobar', 'HS256') }

    before do
      header 'Authorization', "Bearer #{token}"
      get '/'
    end

    it 'returns an unauthorized response' do
      expect(last_response.status).to eq 401
    end

    it 'returns a message indicating the token was invalid' do
      expect(last_response.body).to eq 'The authorization token provided was invalid.'
    end
  end

  context 'when the token is valid' do
    let(:payload) { { 'sub' => 'example', 'uid' => 123 } }
    let(:token) { JWT.encode(payload, secret, 'HS256') }

    before do
      header 'Authorization', "Bearer #{token}"
      get '/'
    end

    it 'falls through to the app response' do
      expect(last_response.body).to eq 'Hello World!'
    end

    it 'adds the JWT payload to the Rack environment' do
      expect(last_request.env['jwt.payload']).to eq payload
    end

    it 'adds a token object to the Rack environment' do
      token_obj = last_request.env['jwt.token']
      expect(token_obj.subject).to eq 'example'
      expect(token_obj.user_id).to eq 123
    end
  end
end

RSpec.describe Courier::Middleware::JWTToken do
  let(:payload) { {} }
  subject { described_class.new(payload) }

  describe '#payload' do
    let(:payload) { { 'a' => 'b' } }

    it 'returns the payload given' do
      expect(subject.payload).to eq payload
    end
  end

  describe '#subject' do
    context 'when the payload does not include a "sub" key' do
      it 'returns nil' do
        expect(subject.subject).to be_nil
      end
    end

    context 'when the payload includes a "sub" key' do
      let(:payload) { { 'sub' => 'example' } }

      it 'returns the value' do
        expect(subject.subject).to eq 'example'
      end
    end
  end

  describe '#user_id' do
    context 'when the payload does not include a "uid" key' do
      it 'returns nil' do
        expect(subject.user_id).to be_nil
      end
    end

    context 'when the payload includes a "uid" key' do
      let(:payload) { { 'uid' => 123 } }

      it 'returns the value' do
        expect(subject.user_id).to eq 123
      end
    end
  end

  describe '#roles' do
    context 'when the payload does not include a "roles" key' do
      it 'returns an empty array' do
        expect(subject.roles).to eq []
      end
    end

    context 'when the payload includes a "roles" key' do
      let(:payload) { { 'roles' => %w[service foo] } }

      it 'returns the value' do
        expect(subject.roles).to eq %w[service foo]
      end
    end
  end

  describe '#role?' do
    context 'when the payload does not include a "roles" key' do
      it 'returns false for any value' do
        expect(subject.role?('foo')).to be false
      end
    end

    context 'when the payload includes a "roles" key' do
      let(:payload) { { 'roles' => %w[foo bar] } }

      it 'returns false if the role is not in the list' do
        expect(subject.role?('baz')).to be false
      end

      it 'returns true if the role is in the list' do
        expect(subject.role?('foo')).to be true
      end
    end
  end
end

RSpec.describe Courier::Service do
  it 'has a version number' do
    expect(Courier::Service::VERSION).not_to be nil
  end

  describe 'loading environment variables' do
    let(:adapter) { double(:adapter, file: file) }
    let(:file) do
      StringIO.new <<~ENV
        export FOO="baz"
        export A_NEW_VAR="my dude"
        export MOTD="this file can hold so many env vars"
        ENV
    end
    subject { Courier::ServiceEnvironment.new(env: env, adapter: adapter) }

    context 'when running in the development environment' do
      let(:env) { { 'RACK_ENV' => 'development', 'FOO' => 'bar' } }

      it 'does not alter the environment' do
        expect(subject.environment).to match env
      end
    end

    context 'when running in the production environment' do
      let(:env) { { 'RACK_ENV' => 'production', 'FOO' => 'bar' } }

      it 'merges in variables from the .envrc file' do
        expect(subject.environment).to match({
          'RACK_ENV' => 'production',
          'FOO' => 'baz',
          'A_NEW_VAR' => 'my dude',
          'MOTD' => 'this file can hold so many env vars'
        })
      end
    end
  end
end

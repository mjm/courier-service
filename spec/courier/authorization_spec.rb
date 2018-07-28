RSpec.describe Courier::Authorization do
  include Courier::Authorization
  Token = Courier::Middleware::JWTToken

  let(:env) { {} }

  describe '#require_token' do
    let(:result) { require_token(env) { 'hello' } }

    context 'when the environment does not have a token' do
      it 'returns an unauthenticated error' do
        expect(result).to be_a Twirp::Error
        expect(result.code).to be :unauthenticated
      end
    end

    context 'when the environment has a token' do
      let(:env) { { token: Token.new({}) } }

      it 'returns the value returned by the block' do
        expect(result).to eq 'hello'
      end
    end
  end

  describe '#require_user' do
    context 'when checking for a matching user id' do
      let(:result) { require_user(env, id: 123) { 'hello' } }

      context 'and the environment does not have a token' do
        it 'returns an unauthenticated error' do
          expect(result).to be_a Twirp::Error
          expect(result.code).to be :unauthenticated
        end
      end

      context 'and the environment has a token for a different user id' do
        let(:token) { Token.new('uid' => 134) }
        let(:env) { { token: token } }

        it 'returns a forbidden error' do
          expect(result).to be_a Twirp::Error
          expect(result.code).to be :resource_exhausted
        end
      end

      context 'and the environment has a token for the user id' do
        let(:token) { Token.new('uid' => 123) }
        let(:env) { { token: token } }

        it 'returns the value returned by the block' do
          expect(result).to eq 'hello'
        end
      end

      context 'and the environment has a token for a microservice' do
        let(:token) { Token.new('sub' => 'courier-posts', 'roles' => ['service']) }
        let(:env) { { token: token } }

        it 'returns a forbidden error' do
          expect(result).to be_a Twirp::Error
          expect(result.code).to be :resource_exhausted
        end
      end

      context 'and a service token is allowed' do
        let(:result) { require_user(env, id: 123, allow_service: true) { 'hello' } }

        context 'and the environment has a token for the user id' do
          let(:token) { Token.new('uid' => 123) }
          let(:env) { { token: token } }

          it 'returns the value returned by the block' do
            expect(result).to eq 'hello'
          end
        end

        context 'and the environment has a token for a microservice' do
          let(:token) { Token.new('sub' => 'courier-posts', 'roles' => ['service']) }
          let(:env) { { token: token } }

          it 'returns the value returned by the block' do
            expect(result).to eq 'hello'
          end
        end
      end
    end

    context 'when checking for a matching username' do
      let(:result) { require_user(env, name: 'example') { 'hello' } }

      context 'and the environment does not have a token' do
        it 'returns an unauthenticated error' do
          expect(result).to be_a Twirp::Error
          expect(result.code).to be :unauthenticated
        end
      end

      context 'and the environment has a token for a different username' do
        let(:token) { Token.new('sub' => 'example2') }
        let(:env) { { token: token } }

        it 'returns a forbidden error' do
          expect(result).to be_a Twirp::Error
          expect(result.code).to be :resource_exhausted
        end
      end

      context 'and the environment has a token for the username' do
        let(:token) { Token.new('sub' => 'example') }
        let(:env) { { token: token } }

        it 'returns the value returned by the block' do
          expect(result).to eq 'hello'
        end
      end

      context 'and the environment has a token for a microservice' do
        let(:token) { Token.new('sub' => 'courier-posts', 'roles' => ['service']) }
        let(:env) { { token: token } }

        it 'returns a forbidden error' do
          expect(result).to be_a Twirp::Error
          expect(result.code).to be :resource_exhausted
        end
      end

      context 'and a service token is allowed' do
        let(:result) { require_user(env, name: 'example', allow_service: true) { 'hello' } }

        context 'and the environment has a token for the username' do
          let(:token) { Token.new('sub' => 'example') }
          let(:env) { { token: token } }

          it 'returns the value returned by the block' do
            expect(result).to eq 'hello'
          end
        end

        context 'and the environment has a token for a microservice' do
          let(:token) { Token.new('sub' => 'courier-posts', 'roles' => ['service']) }
          let(:env) { { token: token } }

          it 'returns the value returned by the block' do
            expect(result).to eq 'hello'
          end
        end
      end
    end
  end
end

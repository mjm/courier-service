require 'jwt'
require 'base64'

module Courier
  module Middleware
    class JWT
      def initialize(app, algorithm: 'HS256', secret: Base64.decode64(ENV['JWT_SECRET']))
        @app = app
        @algorithm = algorithm
        @secret = secret
        yield self if block_given?
      end

      def call(env)
        if (auth = env['HTTP_AUTHORIZATION']) && auth.start_with?('Bearer ')
          decode_token auth, env
        end

        @app.call(env)
      rescue ::JWT::DecodeError
        [401, { 'Content-Type' => 'text/plain' }, ['The authorization token provided was invalid.']]
      rescue ::JWT::ExpiredSignature
        [403, { 'Content-Type' => 'text/plain' }, ['The authorization token has expired.']]
      end

      def print_token(payload)
        puts 'You can use the following token to log in:'
        puts ::JWT.encode(payload, @secret, @algorithm)
      end

      private

      def decode_token(auth, env)
        token = auth.slice(7..-1)
        payload, = ::JWT.decode(token, @secret, true, algorithm: @algorithm)

        env['jwt.payload'] = payload
        env['jwt.token'] = JWTToken.new(payload)
      end
    end

    class JWTToken
      attr_reader :payload

      def initialize(payload)
        @payload = payload
      end

      def subject
        payload['sub']
      end

      def roles
        payload.fetch('roles', [])
      end

      def role?(role)
        roles.include? role.to_s
      end
    end
  end
end

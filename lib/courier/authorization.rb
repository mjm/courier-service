require 'twirp'

module Courier
  module Authorization
    def require_token(env)
      return unauthenticated_error unless env[:token]
      yield
    end

    def require_user(env, id: nil, name: nil, allow_service: false)
      require_token env do
        return yield if allow_service && env[:token].role?('service')

        if id
          return forbidden_error unless env[:token].user_id == id
        end

        if name
          return forbidden_error unless env[:token].subject == name
        end

        yield
      end
    end

    def require_service(env)
      require_token env do
        return forbidden_error unless env[:token].role?('service')

        yield
      end
    end

    private

    def unauthenticated_error
      Twirp::Error.unauthenticated 'No auth token given'
    end

    def forbidden_error
      Twirp::Error.resource_exhausted 'You cannot perform this action'
    end
  end
end

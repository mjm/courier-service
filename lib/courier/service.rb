require 'pathname'

require 'courier/service/version'
require 'courier/authorization'
require 'courier/middleware/documentation'
require 'courier/middleware/jwt'

module Courier
  module Service
    class Configuration
      def root(dir = nil, *joins)
        if dir
          @root = Pathname.new(dir)
          @root = @root.join(*joins)
        else
          @root
        end
      end

      def database
        Object.const_set('DB', Sequel.connect(ENV['DATABASE_URL']))
        Sequel::Model.plugin :json_serializer
      end

      def background_jobs
        Sidekiq.configure_client do |config|
          config.redis = { size: 1 }
        end
        Sidekiq.configure_server do |config|
          config.redis = { size: 7 }
        end
      end
    end

    CONFIG = Configuration.new

    class << self
      def configure(&block)
        CONFIG.instance_eval(&block)

        $LOAD_PATH.unshift(root / 'lib')
        %i[models middlewares helpers service workers].each do |dir|
          require_app dir
        end
      end

      def root
        CONFIG.root
      end

      def require_app(dir)
        (root / 'app' / dir.to_s)
          .glob('*.rb')
          .each { |file| require file }
      end
    end
  end
end

require 'courier/service/version'

module Courier
  module Service
    BUCKET_KEY = 'GOOGLE_CLOUD_STORAGE_BUCKET'.freeze

    def self.load_environment_variables(
      adapter: GoogleStorageAdapter.new(ENV[BUCKET_KEY])
    )
      new_env = ServiceEnvironment.new(env: ENV.to_h, adapter: adapter)
      ENV.replace(new_env.environment)
    end
  end

  class ServiceEnvironment
    def initialize(env:, adapter:)
      @env = env
      @adapter = adapter
    end

    def rack_env
      (@env['RACK_ENV'] || 'development').to_sym
    end

    def production?
      rack_env == :production
    end

    def environment
      return @env unless production?
      env = @env.dup

      @adapter.file('.envrc').each_line do |line|
        /^export (\w+)="(.*)"$/.match line do |m|
          env[m[1]] = m[2]
        end
      end

      env
    end
  end

  class GoogleStorageAdapter
    def initialize(bucket_name)
      @bucket_name = bucket_name
    end

    def bucket
      @bucket ||= begin
                    require 'google/cloud/storage'
                    Google::Cloud::Storage.new.bucket(@bucket_name)
                  end
    end

    def file(name)
      file = bucket.file(name).download
      file.rewind
      file
    end
  end
end

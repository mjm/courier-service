module Courier
  module Middleware
    # Rack middleware to serve the protobuf documentation for GET /
    #
    # This is basically a single-serve middleware for serving a static HTML
    # file, but I think it works well enough for our purposes.
    class Documentation
      def initialize(app, root, path = 'doc/index.html')
        @app = app
        @root = root
        @path = path
      end

      def call(env)
        return @app.call(env) unless doc_request?(env)

        [200, { 'Content-Type' => 'text/html' },
         [File.read(File.join(@root, @path))]]
      end

      def doc_request?(env)
        env['REQUEST_METHOD'] == 'GET' && env['PATH_INFO'] =~ %r{^/?$}
      end
    end
  end
end

require 'rack'
require 'fernet'


module Rack
  module Auth
    class Fernet < Rack::Auth::Basic
      def initialize(app, secret, realm=nil)
        @app = app
        @realm = realm
        @secret = secret
      end

      private
      def valid?(auth)
        verifier = ::Fernet.verifier(@secret, auth.credentials.last)
        verifier.valid?
      end
    end
  end

  class Fernet
    def initialize(app, secret, content_type="application/json")
      @app = app
      @secret = secret
      @content_type = content_type
    end

    def call(env)
      if env["CONTENT_TYPE"] != 'application/octect-stream' && !env["rack.input"].size.zero?
        verifier = ::Fernet.verifier(@secret, env["rack.input"].read)
        if verifier.valid?
          env['CONTENT_TYPE'] = @content_type
          env["rack.input"] = StringIO.new(verifier.data || verifier.message)
          @app.call(env)
        else
          bad_request
        end
      else
        @app.call(env)
      end
    end

    private
    def bad_request
      return [ 400,
        { 'Content-Type' => 'text/plain',
          'Content-Length' => '0' },
        []
      ]
    end
  end
end
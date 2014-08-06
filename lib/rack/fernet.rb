require 'fernet'
require 'json'
require 'rack'


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
      secret = if @secret.respond_to?(:call)
        @secret.call(env)
      else
        @secret
      end
      payload = env["rack.input"].read
      verifier = ::Fernet.verifier(secret, payload)
      if verifier.valid?
        env["CONTENT_TYPE"] = @content_type
        env["rack.input"] = StringIO.new(verifier.message)
        @app.call(env)
      elsif payload.size.zero?
        @app.call(env)
      else
        bad_request
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

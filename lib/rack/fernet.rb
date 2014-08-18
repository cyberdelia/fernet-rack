require 'fernet'
require 'json'
require 'rack'


module Rack
  class FernetError < StandardError; end

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
      payload = env["rack.input"].read
      env["CONTENT_TYPE"] = @content_type

      unless payload.empty?
        payload = decrypt_request(env, payload)
        env["rack.input"] = StringIO.new(payload)
      end

      status, headers, body = @app.call(env)
      str_body = read_body(body)
      unless str_body.empty?
        encoded = encrypt_response(env, str_body)
        headers['Content-Type'] = 'application/octet-stream'
        headers['Content-Length'] = encoded.length
        body = [ encoded ]
      end
      [status, headers, body]
    rescue ::Fernet::Error
      bad_request
    end

    private

    def read_body(body)
      if body.respond_to? :join
        body.join('')
      else
        result = []
        body.each { |line| result << line }
        result.join('')
      end
    end

    def secret(env)
      if @secret.respond_to?(:call)
        @secret.call(env)
      else
        @secret
      end
    end

    def encrypt_response(env, payload)
      ::Fernet.generate(secret(env), payload)
    end

    def decrypt_request(env, payload)
      # read the payload
      verifier = ::Fernet.verifier(secret(env), payload)
      if verifier.valid?
        verifier.message
      else
        raise ::Fernet::Error
      end
    end

    def bad_request
      return [ 400,
        { 'Content-Type' => 'text/plain',
          'Content-Length' => '0' },
        []
      ]
    end
  end
end

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
end
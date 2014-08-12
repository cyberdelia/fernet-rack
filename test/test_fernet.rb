require 'minitest/autorun'
require 'rack/fernet'
require 'rack/lint'
require 'rack/mock'

class FernetTest < Minitest::Test
  def setup
    @secret = "SqD5Mz/qFnXPLVTvkQKRDyVpli3Q6/habc7i89IrBRA="
    @app = Rack::Fernet.new(unprotected_app, @secret)
    @request = Rack::MockRequest.new(@app)
  end

  def test_invalid_signature
    request("garbage") do |response|
      assert_equal(400, response.status)
    end
  end

  def test_valid_signature
    data = '{"hello"=>"world"}'
    request(encrypt(data)) do |response|
      assert_equal(200, response.status)
      assert_equal(data, decrypt(response.body))
      assert_equal('application/octet-stream', response.headers['Content-Type'])
    end
  end

  def test_empty_payload
    request do |response|
      assert_equal(200, response.status)
    end
  end

  protected
  def unprotected_app
    Rack::Lint.new(lambda do |env|
      request_body = env["rack.input"].read
      content_type = env["CONTENT_TYPE"].to_s
      unless request_body.empty?
        assert_equal('application/json', content_type)
      end
      [ 200, {'Content-Type' => content_type }, [request_body] ]
    end)
  end

  def request(body='', headers={})
    yield @request.get('/', :input => body, 'CONTENT_TYPE' => 'application/octet-stream')
  end

  def encrypt(data)
    Fernet.generate(@secret, data)
  end

  def decrypt(data)
    verifier = Fernet.verifier(@secret, data)
    if verifier.valid?
      verifier.message
    end
  end
end

class DynamicFernetTest < FernetTest
  def setup
    @secret = ->(env) { "SqD5Mz/qFnXPLVTvkQKRDyVpli3Q6/habc7i89IrBRA=" }
    @app = Rack::Fernet.new(unprotected_app, @secret)
    @request = Rack::MockRequest.new(@app)
  end

  protected
  def encrypt(data)
    Fernet.generate(@secret.call(nil), data)
  end

  def decrypt(data)
    verifier = Fernet.verifier(@secret.call(nil), data)
    if verifier.valid?
      verifier.message
    end
  end
end

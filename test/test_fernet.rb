require 'minitest/autorun'
require 'rack/fernet'
require 'rack/lint'
require 'rack/mock'


class FernetTest < Minitest::Test
  def setup
    unprotected_app = Rack::Lint.new(lambda do |env|
      [ 200, {'Content-Type' => env["CONTENT_TYPE"].to_s }, [env["rack.input"].read] ]
    end)
    @secret = "SqD5Mz/qFnXPLVTvkQKRDyVpli3Q6/habc7i89IrBRA="
    @app = Rack::Fernet.new(unprotected_app, @secret)
    @request = Rack::MockRequest.new(@app)
  end

  def test_invalid_signature
    request("garbage") do |response|
      assert_equal(response.status, 400)
    end
  end

  def test_valid_signature
    data = Fernet.generate(@secret, '{}')
    request(data) do |response|
      assert_equal(response.status, 200)
      assert_equal(response.body, '{}')
      assert_equal(response.headers['Content-Type'], 'application/json')
    end
  end

  def test_empty_payload
    request do |response|
      assert_equal(response.status, 200)
    end
  end

  private
  def request(body=nil, headers={})
    yield @request.get('/', input: body, CONTENT_TYPE: 'application/octet-stream')
  end
end
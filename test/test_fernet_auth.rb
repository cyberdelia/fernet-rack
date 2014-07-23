require 'minitest/autorun'
require 'rack/fernet'
require 'rack/lint'
require 'rack/mock'


class FernetAuthTest < Minitest::Test
  def setup
    unprotected_app = Rack::Lint.new(lambda do |env|
      [ 200, {'Content-Type' => 'text/plain'}, ["Hello"] ]
    end)
    @realm = "Lillet"
    @secret = "SqD5Mz/qFnXPLVTvkQKRDyVpli3Q6/habc7i89IrBRA="
    @app = Rack::Auth::Fernet.new(unprotected_app, @secret, @realm)
    @request = Rack::MockRequest.new(@app)
  end

  def test_no_credentials
    request do |response|
      assert_basic_auth_challenge(response)
    end
  end

  def test_wrong_credentials
    request_with_auth('token') do |response|
      assert_basic_auth_challenge(response)
    end
  end

  def test_correct_credentials
    token = Fernet.generate(@secret, 'Podensac')
    request_with_auth(token) do |response|
      assert_equal(response.status, 200)
      assert_equal(response.body, "Hello")
    end
  end

  private
  def request(headers={})
    yield @request.get('/', headers)
  end

  def request_with_auth(token, &block)
    request('HTTP_AUTHORIZATION' => 'Basic ' + [":#{token}"].pack("m*"), &block)
  end

  def assert_basic_auth_challenge(response)
    assert_equal(response.status, 401)
    assert_includes(response, 'WWW-Authenticate')
    assert(response.headers['WWW-Authenticate'] =~ /Basic realm="#{Regexp.escape(@realm)}"/)
    assert_empty(response.body)
  end
end
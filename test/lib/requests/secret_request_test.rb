# test/models/cert_issue_request_test.rb
require "test_helper"

class SecretRequestTest < ActiveSupport::TestCase
  def setup
    @attributes = {
      path: "my/top/secret",
      data: {
        "password": "t0p-s3cret"
      }
    }
    @secret_request = Requests::SecretRequest.new(@attributes)
  end

  test "#new should set attributes from attributes argument" do
    @attributes.each do |key, value|
      assert_equal value, @secret_request.send(key), "Attribute #{key} was not set correctly"
    end
  end

  test "#valid? should be valid with valid attributes" do
    assert @secret_request.valid?
  end

  test "#valid? should require a path" do
    @secret_request.path = nil
    assert_not @secret_request.valid?
    assert_includes @secret_request.errors[:path], "can't be blank"
  end

  test "#kv_path should be an alias for #path" do
    assert @attributes[:path], @secret_request.kv_path
  end
end

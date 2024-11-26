require "test_helper"

class AuthenticateIdentityTest < ActiveSupport::TestCase
  def setup
    @interactor = AuthenticateIdentity
    @identity = Identity.new(subject: "test@example.com", groups: [ "admin_group" ])
    Thread.current[:request_id] = "request_id"
  end

  test ".call success" do
    request = OpenStruct.new(headers: { "Authorization" => "Bearer valid_token" })
    mock = Minitest::Mock.new
    mock.expect :call, @identity, [ "valid_token" ]
    Services::Auth.stub :authenticate!, mock do
      context = @interactor.call(request: request)
      assert context.success?
      assert_equal @identity, context.identity
    end
  end

  test ".call failure" do
    request = OpenStruct.new(headers: { "Authorization" => "Bearer invalid_token" })
    mock = Minitest::Mock.new
    mock.expect :call, nil, [ "invalid_token" ]
    Services::Auth.stub :authenticate!, mock do
      context = @interactor.call(request: request)
      assert context.failure?
      assert_nil context.identity
    end
  end
end

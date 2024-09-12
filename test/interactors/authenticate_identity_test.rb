require "test_helper"

class AuthenticateIdentityTest < ActiveSupport::TestCase
  def setup
    @interactor = AuthenticateIdentity
    @identity = Identity.new(subject: "test@example.com", groups: [ "admin_group" ])
  end

  test ".call success" do
    request = OpenStruct.new(headers: { "Authorization" => "Bearer valid_token" })
    srv = Minitest::Mock.new
    srv.expect :authenticate!, @identity, [ "valid_token" ]
    Services::AuthService.stub :new, srv do
      context = @interactor.call(request: request)
      assert context.success?
      assert_equal @identity, context.identity
    end
  end

  test ".call failure" do
    request = OpenStruct.new(headers: { "Authorization" => "Bearer invalid_token" })
    srv = Minitest::Mock.new
    srv.expect :authenticate!, nil, [ "invalid_token" ]
    Services::AuthService.stub :new, srv do
      context = @interactor.call(request: request)
      assert context.failure?
      assert_nil context.identity
    end
  end
end

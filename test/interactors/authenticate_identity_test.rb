require "test_helper"

class AuthenticateIdentityTest < ActiveSupport::TestCase
  def setup
    @interactor = AuthenticateIdentity
    @identity = Identity.new(subject: "test@example.com", groups: [ "admin_group" ])
  end

  test "successful call" do
    request = OpenStruct.new(headers: { "Authorization" => "Bearer valid_token" })
    srv = Minitest::Mock.new
    srv.expect :authenticate!, @identity, [ "valid_token" ]
    Services::AuthService.stub :new, srv do
      context = @interactor.call(request: request)
      assert context.success?
      assert_equal @identity, context.identity
    end
  end

  test "unsuccessful call" do
    request = OpenStruct.new(headers: { "Authorization" => "Bearer invalid_token" })
    srv = Minitest::Mock.new
    srv.expect :authenticate!, nil, [ "invalid_token" ]
    Services::AuthService.stub :new, srv do
      context = @interactor.call(request: request)
      assert_not context.success?
      assert_nil context.identity
    end
  end
end

require "test_helper"

class AuthorizeRequestTest < ActiveSupport::TestCase
  def setup
    @domain = domains(:group_match)
    @identity = Identity.new(subject: @domain.owner)
    @cr = CertIssueRequest.new(common_name: @domain.fqdn)
    @interactor = AuthorizeRequest
  end

  test "successful call" do
    request = CertIssueRequest.new(common_name: @domain.fqdn)
    srv = Minitest::Mock.new
    srv.expect :authorize!, nil, [ @identity, @cr ]
    Services::DomainOwnershipService.stub :new, srv do
      context = @interactor.call(identity: @identity, request: @cr)
      assert context.success?
    end
  end

  test "unsuccessful call" do
    request = CertIssueRequest.new(common_name: @domain.fqdn)
    srv = Services::DomainOwnershipService.new
    Services::DomainOwnershipService.stub :new, srv do
      err = ->(_, _) { raise AuthError.new "no can do" }
      srv.stub :authorize!, err do
        context = @interactor.call(identity: @identity, request: @cr)
        assert_not context.success?
        assert_kind_of AuthError, context.error
      end
    end
  end
end

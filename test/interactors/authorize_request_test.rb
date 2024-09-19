require "test_helper"

class AuthorizeRequestTest < ActiveSupport::TestCase
  def setup
    @domain = domains(:group_match)
    @identity = Identity.new(subject: @domain.users_array.first)
    @cr = CertIssueRequest.new(common_name: @domain.fqdn)
    @interactor = AuthorizeRequest
  end

  test ".call with matching owner" do
    rslt = @interactor.call(identity: @identity, request: @cr)
    assert rslt.success?
  end

  test ".call with non-matching owner" do
    @identity.subject = "different_owner@example.com"
    rslt = @interactor.call(identity: @identity, request: @cr)
    assert_not rslt.success?
    assert_kind_of AuthError, rslt.error
  end

  test ".call with matching group" do
    @domain.update(users: "different_owner@example.com")
    @identity.groups = [ @domain.groups_array.first ]
    rslt = @interactor.call(identity: @identity, request: @cr)
    assert rslt.success?
  end

  test ".call with non-matching group" do
    @domain.update(users: "different_owner@example.com")
    @identity.groups = [ "different_group" ]
    rslt = @interactor.call(identity: @identity, request: @cr)
    assert_not rslt.success?
    assert_kind_of AuthError, rslt.error
  end
end
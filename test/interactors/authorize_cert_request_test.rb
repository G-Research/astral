require "test_helper"

class AuthorizeCertRequestTest < ActiveSupport::TestCase
  def setup
    @domain = domains(:group_match)
    @identity = Identity.new(subject: @domain.users.first)
    @cr = Requests::CertIssueRequest.new(common_name: @domain.fqdn)
    @interactor = AuthorizeCertRequest
    Thread.current[:request_id] = "request_id"
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
    @domain.update(users: [ "different_owner@example.com" ])
    @identity.groups = [ @domain.groups.first ]
    rslt = @interactor.call(identity: @identity, request: @cr)
    assert rslt.success?
  end

  test ".call with non-matching group" do
    @domain.update(users: [ "different_owner@example.com" ])
    @identity.groups = [ "different_group" ]
    rslt = @interactor.call(identity: @identity, request: @cr)
    assert_not rslt.success?
    assert_kind_of AuthError, rslt.error
  end
end

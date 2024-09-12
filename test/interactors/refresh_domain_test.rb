require "test_helper"

class RefreshDomainTest < ActiveSupport::TestCase
  def setup
    @domain = domains(:owner_match)
    @identity = Identity.new(subject: @domain.users_array.first)
    @cr = CertIssueRequest.new(common_name: @domain.fqdn)
    @interactor = RefreshDomain
  end

  test ".call updates db record with service response when 200" do
    rslt = @interactor.call(identity: @identity, request: @cr)
    assert rslt.success?
    reloaded = Domain.where(fqdn: @domain.fqdn).first!
    assert_not_equal @domain.users, reloaded.users
    assert_not_equal @domain.groups, reloaded.groups
    assert_not_equal @domain.group_delegation, reloaded.group_delegation
  end

  test ".call deletes db record when service 404" do
    @domain = domains(:no_match) # this fixture should have no match
    @cr = CertIssueRequest.new(common_name: @domain.fqdn)
    rslt = @interactor.call(identity: @identity, request: @cr)
    assert rslt.success?
    reloaded = Domain.where(fqdn: @domain.fqdn).first
    assert_nil reloaded
  end

  test ".call leaves db record as-is when service has error" do
    mock = Services::DomainOwnershipService.new
    err = ->(_) { raise Faraday::TimeoutError.new }
    mock.stub(:get_domain_info, err) do
      Services::DomainOwnershipService.stub :new, mock do
        rslt = @interactor.call(identity: @identity, request: @cr)
        assert rslt.success?
        reloaded = Domain.where(fqdn: @domain.fqdn).first!
        assert_equal @domain.users, reloaded.users
      end
    end
  end
end

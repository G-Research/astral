require "test_helper"

class DomainOwnershipServiceTest < ActiveSupport::TestCase
  def setup
    @domain = domains(:group_match)
    @identity = Identity.new(subject: @domain.owner)
    @cr = CertIssueRequest.new(common_name: @domain.fqdn)
    @ds = Services::DomainOwnershipService.new
  end

  test "#authorize! with matching owner" do
    assert_nil(@ds.authorize!(@identity, @cr))
  end

  test "#authorize! with non-matching owner" do
    @identity.subject = "different_owner@example.com"
    assert_raises(AuthError) do
      @ds.authorize!(@identity, @cr)
    end
  end

  test "#authorize! with matching group" do
    @domain.update(owner: "different_owner@example.com")
    @identity.groups = @domain.groups
    assert_nil(@ds.authorize!(@identity, @cr))
  end

  test "#authorize! with non-matching group" do
    @domain.update(owner: "different_owner@example.com")
    @identity.groups = [ "different_group" ]
    assert_raises(AuthError) do
      @ds.authorize!(@identity, @cr)
    end
  end
end

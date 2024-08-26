require "test_helper"

class DomainOwnershipServiceTest < ActiveSupport::TestCase
  def setup
    @identity = Identity.new(subject: "test@example.com", groups: [ "admin_group" ])
    @domain = DomainInfo.new(owner: "test@example.com", group_delegation: false, groups: [ "admin_group" ])
  end

  test "#authorize! with matching owner" do
    ds = Services::DomainOwnershipService.new
    ds.stub :get_domain_name, @domain do
      assert_nil(ds.authorize!(@identity, CertIssueRequest.new))
    end
  end

  test "#authorize! with non-matching owner" do
    ds = Services::DomainOwnershipService.new
    @domain.owner = "different_owner@example.com"
    ds.stub :get_domain_name, @domain do
      assert_raises(AuthError) do
        ds.authorize!(@identity, CertIssueRequest.new)
      end
    end
  end

  test "#authorize! with matching group" do
    ds = Services::DomainOwnershipService.new
    @domain.owner = "different_owner@example.com"
    @domain.group_delegation = true
    ds.stub :get_domain_name, @domain do
      assert_nil(ds.authorize!(@identity, CertIssueRequest.new))
    end
  end

  test "#authorize! with non-matching group" do
    ds = Services::DomainOwnershipService.new
    @domain.owner = "different_owner@example.com"
    @identity.groups = [ "different_group" ]
    ds.stub :get_domain_name, @domain do
      assert_raises(AuthError) do
        ds.authorize!(@identity, CertIssueRequest.new)
      end
    end
  end
end

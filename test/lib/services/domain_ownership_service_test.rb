require "test_helper"

class DomainOwnershipServiceTest < ActiveSupport::TestCase
  setup do
    @service = Services::DomainOwnershipService.new
  end

  test "#get_domain_info fetches from configured api server" do
    domain_info = @service.get_domain_info(domains(:owner_match).fqdn)
    assert_not_nil domain_info
    assert_equal "group1", domain_info.groups
    assert_equal "john.doe@example.com", domain_info.users
    assert_equal "example.com", domain_info.fqdn
    assert domain_info.group_delegation
  end

  test "#get_domain_info returns nil for unmatched fqdn" do
    domain_info = @service.get_domain_info(domains(:no_match).fqdn)
    assert_nil domain_info
  end
end

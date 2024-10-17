require "test_helper"
require_relative "../../../app/lib/utils/oidc_provider"

class OidcProviderTest < ActiveSupport::TestCase
  setup do
    @provider = OidcProvider.new
  end

  test ".get_info returns correct info" do
    info = @provider.get_info
    assert_equal Config[:oidc_issuer], info.data[:issuer]
    assert_equal "email", info.data[:scopes_supported][0]
  end

  test ".get_client_info return correct info" do
    info = @provider.get_client_info
    assert_equal Config[:oidc_client_id], info[0]
    assert_equal Config[:oidc_client_secret], info[1]
  end
end

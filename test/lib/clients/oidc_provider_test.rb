require "test_helper"

class OidcProviderTest < ActiveSupport::TestCase
  setup do
    @provider = OidcProvider.new
    @info = @provider.get_info
  end

  test ".get_info returns correct info" do
    assert_equal "email", @info.data[:scopes_supported][0]
  end

  test ".get_issuer returns correct issuer" do
    issuer = @provider.get_issuer
    assert_equal @info.data[:issuer], issuer
  end

  test ".get_client_info return correct info" do
    info = @provider.get_client_info
    assert_equal Config[:oidc_client_id], info[0]
    assert_equal Config[:oidc_client_secret], info[1]
  end
end

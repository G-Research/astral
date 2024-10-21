require "test_helper"

# NOTE: these tests excercise the OIDC config but can't really verify a
# successful OIDC login.  (Because that requires browser interaction.)
# See the readme for how to use oidc login with the browser.

class OidcTest < ActiveSupport::TestCase
  setup do
    @client = Clients::Vault
    @client.configure_oidc_user(
      Config[:initial_user_name],
      Config[:initial_user_email],
      test_policy)
    @entity = @client.read_entity(Config[:initial_user_name])
  end

  test "policies contain initial users email" do
    assert_equal Config[:initial_user_email], @entity.data[:policies][0]
  end

  test "aliases contain initial users email" do
    aliases = @entity.data[:aliases]
    assert aliases.find { |a| a[:name] == Config[:initial_user_email] }
  end

  test "vault is configured as oidc client" do
    auth = @client.get_oidc_client_config
    assert_equal Config[:oidc_client_id], auth.data[:oidc_client_id]
  end

  private
  def test_policy
    policy = <<-EOH
           path "sys" {
           policy = "read"
           }
           EOH
  end
end

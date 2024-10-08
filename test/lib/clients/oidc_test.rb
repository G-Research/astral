require "test_helper"

class OIDCTest < ActiveSupport::TestCase
  setup do
    @client = Clients::Vault
  end

  test ".configure_oidc_user" do
    policy = <<-EOH
           path "sys" {
           policy = "deny"
           }
           EOH
    @client.configure_oidc_user(Config[:test_user][:name], Config[:test_user][:email], policy)
    entity = @client.read_entity(Config[:test_user][:name])
    assert_equal Config[:test_user][:email], entity.data[:policies][0]
    aliases = entity.data[:aliases]
    assert aliases.find { |a| a[:name] == Config[:test_user][:email] }
  end

  private
  def vault_client
    ::Vault::Client.new(
          address: vault_addr,
          token: vault_token
    )
  end

  def vault_addr
    Config[:vault_addr]
  end

  def vault_token
    Config[:vault_token]
  end
end
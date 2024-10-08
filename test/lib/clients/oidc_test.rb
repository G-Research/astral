require "test_helper"

class OIDCTest < ActiveSupport::TestCase
  setup do
    @client = Clients::Vault
  end

  test "#configure_oidc_user" do
    policy = <<-EOH
           path "sys" {
           policy = "read"
           }
           EOH
    @client.configure_oidc_user(Config[:initial_user][:name],
                                Config[:initial_user][:email], policy)
    entity = @client.read_entity(Config[:initial_user][:name])
    assert_equal Config[:initial_user][:email], entity.data[:policies][0]
    aliases = entity.data[:aliases]
    assert aliases.find { |a| a[:name] == Config[:initial_user][:email] }
  end
end

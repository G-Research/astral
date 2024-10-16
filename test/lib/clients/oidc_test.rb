require "test_helper"

# NOTE: these tests excercise the OIDC config but can't really verify a
# successful OIDC login.  (Because that requires browser interaction.)
# See the readme for how to use oidc login with the browser.

class OIDCTest < ActiveSupport::TestCase
  setup do
    @client = Clients::Vault
    @client.configure_oidc_user(initial_user[:name],
                                initial_user[:email], test_policy)
    @entity = @client.read_entity(initial_user[:name])
  end

  test "#policies_contain_initial_users_email" do
    assert_equal initial_user[:email], @entity.data[:policies][0]
  end

  test "#aliases_contain_initial_users_email" do
    aliases = @entity.data[:aliases]
    assert aliases.find { |a| a[:name] == initial_user[:email] }
  end

  private
  def test_policy
    policy = <<-EOH
           path "sys" {
           policy = "read"
           }
           EOH
  end

  def initial_user
    raise "initial user not configured." unless Config[:initial_user]
    Config[:initial_user]
  end

end

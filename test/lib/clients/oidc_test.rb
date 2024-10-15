require "test_helper"

# NOTE: these tests excercise the OIDC config but can't really verify a
# successful OIDC login.  (Because that requires browser interaction.)
# See the readme for how to use oidc login with the browser.

class OIDCTest < ActiveSupport::TestCase
  setup do
    @client = Clients::Vault
    @client.configure_oidc_user(@client.initial_user[:name],
                                @client.initial_user[:email], test_policy)
    @entity = @client.read_entity(@client.initial_user[:name])
  end

  test "#policies_contain_initial_users_email" do
    assert_equal @client.initial_user[:email], @entity.data[:policies][0]
  end

  test "#aliases_contain_initial_users_email" do
    aliases = @entity.data[:aliases]
    assert aliases.find { |a| a[:name] == @client.initial_user[:email] }
  end

  def configure_oidc_provider
        provider = oidc_provider.logical.read("identity/oidc/provider/astral")
        if provider.nil?
          create_provider_webapp
          create_provider_with_email_scope
          create_entity_for_initial_user
          create_userpass_for_initial_user
          map_userpass_to_entity
        else
          set_client_id
        end
      end


  private
      def initial_user
        raise "initial user not configured." unless Config[:initial_user]
        Config[:initial_user]
      end
      cattr_accessor :client_id
      cattr_accessor :client_secret
      cattr_accessor :provider
      WEBAPP_NAME = "identity/oidc/client/astral"

      def oidc_provider
        @@provider ||=
          begin
            ::Vault::Client.new(
              address: "http://oidc_provider:8300",
              token: token
            )
          end
      end

      def create_provider_webapp
        oidc_provider.logical.write(
          WEBAPP_NAME,
          redirect_uris: redirect_uris,
          assignments: "allow_all")
        set_client_id
      end

      def set_client_id
        app = oidc_provider.logical.read(WEBAPP_NAME)
        @@client_id = app.data[:client_id]
        @@client_secret = app.data[:client_secret]
      end

      def create_provider_with_email_scope
        oidc_provider.logical.write("identity/oidc/scope/email",
                                    template: '{"email": {{identity.entity.metadata.email}}}')
        oidc_provider.logical.write("identity/oidc/provider/astral",
                                    issuer: "http://oidc_provider:8300",
                                    allowed_client_ids: @@client_id,
                                    scopes_supported: "email")
        oidc_provider.logical.read("identity/oidc/provider/astral")
      end

      def create_entity_for_initial_user
        oidc_provider.logical.write("identity/entity",
                                    policies: "default",
                                    name: initial_user[:name],
                                    metadata: "email=#{initial_user[:email]}",
                                    disabled: false)
      end

      def create_userpass_for_initial_user
        oidc_provider.logical.delete("/sys/auth/userpass")
        oidc_provider.logical.write("/sys/auth/userpass", type: "userpass")
        oidc_provider.logical.write("/auth/userpass/users/#{initial_user[:name]}",
                                    password: initial_user[:password])
      end

      def map_userpass_to_entity
        entity = oidc_provider.logical.read(
          "identity/entity/name/#{initial_user[:name]}")
        entity_id = entity.data[:id]
        auth_list = oidc_provider.logical.read("/sys/auth")
        accessor = auth_list.data[:"userpass/"][:accessor]
        oidc_provider.logical.write("identity/entity-alias",
                                    name: initial_user[:name],
                                    canonical_id: entity_id,
                                    mount_accessor: accessor)
      end

  def test_policy
    policy = <<-EOH
           path "sys" {
           policy = "read"
           }
           EOH
  end
end

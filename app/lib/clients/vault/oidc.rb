module Clients
  class Vault
    module Oidc
      def configure_oidc_provider
        create_provider_app
        create_provider_with_email_scope
        create_entity_for_initial_user
        create_userpass_for_initial_user
        create_alias_mapping_userpass_to_entity
      end

      def configure_oidc_client
        create_client_config
        create_default_policy_for_role
        create_default_role
      end

      def configure_oidc_user(name, email, policy)
        client.sys.put_policy(email, policy)
        put_entity(name, email)
        put_entity_alias(name, email, "oidc")
      end

      private
      cattr_accessor :client_id
      cattr_accessor :client_secret
      WEBAPP_NAME = "identity/oidc/client/astral"

      def oidc_provider
        ::Vault::Client.new(
          address: Config[:oidc_provider][:addr],
          token: token
        )
      end

      def create_provider_app
        oidc_provider.logical.write(
          WEBAPP_NAME,
          # use localhost:8250, per: https://developer.hashicorp.com/vault/docs/auth/jwt#redirect-uris
          redirect_uris: "http://localhost:8250/oidc/callback",
          assignments: "allow_all")
        app = oidc_provider.logical.read(WEBAPP_NAME)
        @@client_id = app.data[:client_id]
        @@client_secret = app.data[:client_secret]
      end

      def create_provider_with_email_scope
        oidc_provider.logical.write("identity/oidc/scope/email",
                                    template: '{"email": {{identity.entity.metadata.email}}}')
        oidc_provider.logical.write(Config[:oidc_provider][:name],
                                    issuer: Config[:oidc_provider][:addr],
                                    allowed_client_ids: @@client_id,
                                    scopes_supported: "email")
      end

      def create_entity_for_initial_user
        oidc_provider.logical.write("identity/entity",
                                    policies: "default",
                                    name: Config[:initial_user][:name],
                                    metadata: "email=#{Config[:initial_user][:email]}",
                                    disabled: false)
      end

      def create_userpass_for_initial_user
        oidc_provider.logical.delete("/sys/auth/userpass")
        oidc_provider.logical.write("/sys/auth/userpass", type: "userpass")
        oidc_provider.logical.write("/auth/userpass/users/#{Config[:initial_user][:name]}",
                                    password: Config[:initial_user][:password])
      end

      def create_alias_mapping_userpass_to_entity
        op_entity = oidc_provider.logical.read(
          "identity/entity/name/#{Config[:initial_user][:name]}")
        op_entity_id = op_entity.data[:id]
        op_auth_list = oidc_provider.logical.read("/sys/auth")
        up_accessor = op_auth_list.data[:"userpass/"][:accessor]
        oidc_provider.logical.write("identity/entity-alias",
                                    name: Config[:initial_user][:name],
                                    canonical_id: op_entity_id,
                                    mount_accessor: up_accessor)
      end

      def create_client_config
        client.logical.delete("/sys/auth/oidc")
        client.logical.write("/sys/auth/oidc", type: "oidc")
        issuer = "#{Config[:oidc_provider][:addr]}/v1/#{Config[:oidc_provider][:name]}"
        client.logical.write("auth/oidc/config",
                                   oidc_discovery_url: issuer,
                                   oidc_client_id: @@client_id,
                                   oidc_client_secret: @@client_secret,
                                   default_role: "reader")
      end

      def create_default_policy_for_role
        policy = <<-EOH
              path "sys" {
              policy = "read"
              }
              EOH
        client.sys.put_policy("reader", policy)
      end

      def get_redirect_uris
        # use localhost:8250, per: https://developer.hashicorp.com/vault/docs/auth/jwt#redirect-uris
        redirect_uris = <<-EOH
             http://localhost:8250/oidc/callback,
             #{Config[:vault_addr]}/ui/vault/auth/oidc/oidc/callback,
             EOH
      end

      def create_default_role
        client.logical.write(
          "auth/oidc/role/reader",
          bound_audiences: @@client_id,
          allowed_redirect_uris: get_redirect_uris,
          user_claim: "email",
          oidc_scopes: "email",
          token_policies: "reader")
      end
    end
  end
end

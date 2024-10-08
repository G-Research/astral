module Clients
  class Vault
    module Oidc
      def configure_oidc_provider
        # create oidc provider app
        oidc_provider.logical.write(WEBAPP_NAME,
                                    redirect_uris: "http://localhost:8250/oidc/callback",
                                    assignments: "allow_all")
        app = oidc_provider.logical.read(WEBAPP_NAME)
        @@client_id = app.data[:client_id]
        @@client_secret = app.data[:client_secret]

        # create email scope
        oidc_provider.logical.write("identity/oidc/scope/email",
                                    template: '{"email": {{identity.entity.metadata.email}}}')

        # create the provider
        oidc_provider.logical.write(Config[:oidc_provider][:name],
                                    issuer: Config[:oidc_provider][:host],
                                    allowed_client_ids: @@client_id,
                                    scopes_supported: "email")

        # create an entity for an initial user
        oidc_provider.logical.write("identity/entity",
                                    policies: "default",
                                    name: Config[:initial_user][:name],
                                    metadata: "email=#{Config[:initial_user][:email]}",
                                    disabled: false)
        provider = oidc_provider.logical.read(Config[:oidc_provider][:name])

        # create initial userpass for the provider
        oidc_provider.logical.delete("/sys/auth/userpass")
        oidc_provider.logical.write("/sys/auth/userpass", type: "userpass")
        oidc_provider.logical.write(
          "/auth/userpass/users/#{Config[:initial_user][:name]}",
          password: Config[:initial_user][:password])

        # create an alias that maps the userpass to the entity
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

      def configure_oidc_client
        client.logical.delete("/sys/auth/oidc")
        client.logical.write("/sys/auth/oidc", type: "oidc")
        issuer = "#{Config[:oidc_provider][:host]}/v1/#{Config[:oidc_provider][:name]}"
        client.logical.write("auth/oidc/config",
                                   oidc_discovery_url: issuer,
                                   oidc_client_id: @@client_id,
                                   oidc_client_secret: @@client_secret,
                                   default_role: "reader")

        # create default role that all oidc users will receive
        policy = <<-EOH
              path "sys" {
              policy = "read"
              }
              EOH
        client.sys.put_policy("reader", policy)
        uris = <<-EOH
             http://localhost:8200/ui/vault/auth/oidc/oidc/callback,
             http://127.0.0.1:8200/ui/vault/auth/oidc/oidc/callback,
             http://localhost:8250/oidc/callback,
             http://127.0.0.1:8250/oidc/callback
             EOH
        client.logical.write(
          "auth/oidc/role/reader",
          bound_audiences: @@client_id,
          allowed_redirect_uris: uris,
          user_claim: "email",
          oidc_scopes: "email",
          token_policies: "reader")
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
          address: Config[:oidc_provider][:host],
          token: token
        )
      end
    end
  end
end

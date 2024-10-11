=begin

The purpose of this module is to assign a policy to an OIDC user, by
mapping that user's email address to a policy we create.
It works as follows:

It creates an OIDC provider and user.  That user has a
username/password/email addr, that can be accessed with OIDC auth.

It creates an OIDC client which connects to that provider.  When a
user tries to auth, the client connects to the provider, which opens
up a browser window allowing the user to enter his username/password.

On success, the provider returns an OIDC token, which includes the
user's email addr.

The client has been configured to map that email address to an entity
in vault, which has the policy which we want the user to have.

So the mapping goes from the email address on the provider, to the
policy in vault.

Note that this provider is only meant to be used in our dev/test
environment to excercise the client.  In a prod env, a real OIDC
provider is configured in.

=end
module Clients
  class Vault
    module Oidc
      cattr_accessor :provider
      def configure_oidc_provider
        if oidc_provider.logical.read("identity/oidc/provider/astral").nil?
          create_provider_webapp
          create_provider_with_email_scope
          create_entity_for_initial_user
          create_userpass_for_initial_user
          map_userpass_to_entity
        end
      end

      def configure_oidc_client(issuer, client_id, client_secret)
        create_client_config(issuer, client_id, client_secret)
        create_default_policy_for_role
        create_default_role(client_id)
      end

      def configure_oidc_user(name, email, policy)
        client.sys.put_policy(email, policy)
        put_entity(name, email)
        put_entity_alias(name, email, "oidc")
      end

      def initial_user
        if Config[:initial_user].nil?
          raise "initial user not configured."
        end
        Config[:initial_user]
      end
      private
      cattr_accessor :client_id
      cattr_accessor :client_secret
      WEBAPP_NAME = "identity/oidc/client/astral"

      def oidc_provider
        ::Vault::Client.new(
          address: "http://oidc_provider:8300",
          token: token
        )
      end

      def create_provider_webapp
        oidc_provider.logical.write(
          WEBAPP_NAME,
          redirect_uris: redirect_uris,
          assignments: "allow_all")
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

      def create_client_config(issuer, client_id, client_secret)
        client.logical.delete("/sys/auth/oidc")
        client.logical.write("/sys/auth/oidc", type: "oidc")
        client.logical.write("auth/oidc/config",
                                   oidc_discovery_url: issuer,
                                   oidc_client_id: client_id,
                                   oidc_client_secret: client_secret,
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

      def redirect_uris
        # use localhost:8250, per: https://developer.hashicorp.com/vault/docs/auth/jwt#redirect-uris
        redirect_uris = <<-EOH
             http://localhost:8250/oidc/callback,
             #{Config[:vault_addr]}/ui/vault/auth/oidc/oidc/callback,
             EOH
      end

      def create_default_role(client_id)
        client.logical.write(
          "auth/oidc/role/reader",
          bound_audiences: client_id,
          allowed_redirect_uris: redirect_uris,
          user_claim: "email",
          oidc_scopes: "email",
          token_policies: "reader")
      end
    end
  end
end

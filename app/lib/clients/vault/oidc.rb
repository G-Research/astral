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
provider is configured in config/astral.yml

=end
module Clients
  class Vault
    module Oidc
      def configure_oidc_client(issuer, client_id, client_secret)
        create_client_config(issuer, client_id, client_secret)
        create_default_role(client_id)
      end

      def configure_oidc_user(name, email, policy)
        client.sys.put_policy(email, policy)
        put_entity(name, email)
        put_entity_alias(name, email, "oidc")
      end

      private

      def create_client_config(issuer, client_id, client_secret)
        client.logical.delete("/sys/auth/oidc")
        client.logical.write("/sys/auth/oidc", type: "oidc")
        client.logical.write("auth/oidc/config",
                                   oidc_discovery_url: issuer,
                                   oidc_client_id: client_id,
                                   oidc_client_secret: client_secret,
                                   default_role: "default")
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
          "auth/oidc/role/default",
          bound_audiences: client_id,
          allowed_redirect_uris: redirect_uris,
          user_claim: "email",
          oidc_scopes: "email",
          token_policies: "default")
      end
    end
  end
end

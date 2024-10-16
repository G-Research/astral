module Clients
  class Vault
    module Oidc
      def configure_oidc_client(issuer, client_id, client_secret)
        return if client_id.nil?
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
      def create_default_role(client_id)
        client.logical.write(
          "auth/oidc/role/default",
          bound_audiences: client_id,
          allowed_redirect_uris: Config[:oidc_redirect_uris],
          user_claim: "email",
          oidc_scopes: "email",
          token_policies: "default")
      end
    end
  end
end

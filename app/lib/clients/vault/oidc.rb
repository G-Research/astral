module Clients
  class Vault
    module Oidc
      def configure_as_oidc_client(issuer, client_id, client_secret)
        if client_id.nil? || !oidc_auth_data.nil?
          return
        end
        create_client_config(issuer, client_id, client_secret)
        create_default_role(client_id)
      end

      def configure_oidc_user(name, email, policy)
        client.sys.put_policy(email, policy)
        put_entity(name, email)
        put_entity_alias(name, email, "oidc")
      end

      def get_oidc_client_config
        client.logical.read("auth/oidc/config")
      end

      def create_oidc_role(role_name, groups, policy_name)
        client.logical.write("auth/oidc/role/#{role_name}",
                             user_claim: "sub",
                             groups_claim: "groups",
                             bound_claims: { "groups" => groups },
                             policies: policy_name,
                             oidc_scopes: "email groups",
                             allowed_redirect_uris: Config[:oidc_redirect_uris])
      end

      def remove_oidc_role(role_name)
        client.logical.delete("auth/oidc/role/#{role_name}")
      end

      private

      def create_client_config(issuer, client_id, client_secret)
        client.logical.write("/sys/auth/oidc", type: "oidc")
        client.logical.write("auth/oidc/config",
                                   oidc_discovery_url: issuer,
                                   oidc_discovery_ca_pem: File.read(Config[:oidc_provider_ssl_cert]),
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

      def oidc_auth_data
        auth_list = client.logical.read("/sys/auth")
        auth_list.data[:"oidc/"]
      end
    end
  end
end

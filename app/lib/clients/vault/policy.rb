module Clients
  class Vault
    module Policy
      def rotate_token
        create_astral_policy
        token = create_astral_token
        Clients::Vault.token = token
      end

      private

      def create_astral_policy
        policy = <<-HCL
        path "#{intermediate_ca_mount}/roles/astral" {
          capabilities = ["read", "list"]
        }
        path "#{intermediate_ca_mount}/issue/astral" {
          capabilities = ["create", "update"]
        }
        path "#{kv_mount}/data/*" {
          capabilities = ["create", "read", "update", "delete", "list"]
        }
        path "/sys/auth" {
          capabilities = ["read"]
        }
        path "/sys/auth/oidc" {
          capabilities = ["create", "read", "update", "delete", "list", "sudo"]
        }
        path "/sys/policy/*" {
          capabilities = ["create", "read", "update", "delete", "list"]
        }
        path "auth/oidc/config" {
          capabilities = ["create", "read", "update", "delete", "list"]
        }
        path "auth/oidc/role/*" {
          capabilities = ["create", "read", "update", "delete", "list"]
        }
        path "auth/userpass/*" {
          capabilities = ["create", "read", "update", "delete", "list"]
        }
        path "identity/oidc/*" {
          capabilities = ["create", "read", "update", "delete", "list"]
        }
        path "identity/entity-alias" {
          capabilities = ["create", "read", "update", "delete", "list"]
        }
        path "identity/entity" {
          capabilities = ["create", "read", "update", "delete", "list"]
        }
        path "identity/entity/*" {
          capabilities = ["create", "read", "update", "delete", "list"]
        }
        HCL

        client.sys.put_policy("astral_policy", policy)
      end

      def create_astral_token
        token = client.auth_token.create(
          policies: [ "astral_policy" ],
          ttl: "24h"
        )
        token.auth.client_token
      end
    end
  end
end

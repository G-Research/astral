module Clients
  class Vault
    module Policy
      extend Entity

      def rotate_token
        create_astral_policy
        token = create_astral_token
        Clients::Vault.token = token
      end

      def assign_policy(identity, policy_name)
        sub = identity.sub
        email = identity.email
        policies, metadata = get_entity_data(sub)
        policies.append(policy_name).uniq!
        put_entity(sub, policies, metadata)
        put_entity_alias(sub, email, "oidc")
      end

      def verify_policy(identity, policy_name)
        sub = identity.sub
        email = identity.email
        policies, _ = get_entity_data(sub)
        unless policies.any? { |p| p == policy_name }
          raise AuthError.new("Policy has not been granted to the identity")
        end
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
        path "identity/entity" {
          capabilities = ["create", "read", "update", "delete", "list"]
        }
        path "identity/entity/*" {
          capabilities = ["create", "read", "update", "delete", "list"]
        }
        path "identity/entity-alias" {
          capabilities = ["create", "read", "update", "delete", "list"]
        }
        path "/sys/auth" {
          capabilities = ["read"]
        }
        path "auth/oidc/config" {
          capabilities = ["read"]
        }
        path "/sys/policy/*" {
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

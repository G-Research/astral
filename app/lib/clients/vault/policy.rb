module Clients
  class Vault
    module Policy
      extend Entity
      extend Oidc

      def rotate_token
        create_astral_policy
        token = create_astral_token
        Clients::Vault.token = token
      end

      def assign_identity_policy(identity, policy_name)
        sub = identity.sub
        email = identity.email
        Domain.with_advisory_lock(sub) do
          policies, metadata = get_entity_data(sub)
          policies.append(policy_name).uniq!
          put_entity(sub, policies, metadata)
          put_entity_alias(sub, email, "oidc")
        end
      end

      def assign_groups_policy(groups, policy_name)
        create_oidc_role(make_role_name(policy_name), groups, policy_name)
      end

      def verify_policy(identity, producer_policy_name, consumer_policy_name = nil)
        # check identity policies
        sub = identity.sub
        policies, _ = get_entity_data(sub)
        return if policies.any? { |p| p == producer_policy_name }

        # check group role
        if consumer_policy_name.present?
          role = read_oidc_role(make_role_name(consumer_policy_name))
          return if ((role&.data&.dig(:bound_claims, :groups) || []) & identity.groups).any?
        end
        raise AuthError.new("Policy has not been granted to the identity")
      end

      def remove_identity_policy(identity, policy_name)
        sub = identity.sub
        Domain.with_advisory_lock(sub) do
          policies, metadata = get_entity_data(sub)
          policies.reject! { |p| p == policy_name }
          put_entity(sub, policies, metadata)
        end
        client.sys.delete_policy(policy_name)
      end

      def remove_groups_policy(policy_name)
        remove_oidc_role(make_role_name(policy_name))
      end

      private

      def make_role_name(policy_name)
        %Q(#{policy_name.gsub("/", "_")}-role)
      end

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
        path "auth/oidc/role/*" {
          capabilities = ["create", "read", "update", "delete", "list"]
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

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
        groups.each do |group|
          put_group(group, [ policy_name ])
        end
      end

      def verify_policy(identity, producer_policy_name, consumer_groups = nil, consumer_policy_name = nil)
        # check identity policies
        sub = identity.sub
        policies, _ = get_entity_data(sub)
        return if (policies || []).any? { |p| p == producer_policy_name }

        # check group membership in consumer policy if given
        if consumer_groups.present? && consumer_policy_name.present?
          (consumer_groups & identity.groups).each do |group|
            policies, _ = get_group_data(group)
            return if (policies || []).any? { |p| p == consumer_policy_name }
          end
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

      def remove_group_policy(group, policy_name)
        Domain.with_advisory_lock(group) do
          policies, metadata = get_group_data(group)
          policies.reject! { |p| p == policy_name }
          put_group(group, policies, metadata)
        end
        client.sys.delete_policy(policy_name)
      end

      def remove_groups_policy(groups, policy_name)
        groups.each do |group|
          remove_group_policy(group, policy_name)
        end
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
        path "identity/group/*" {
          capabilities = ["create", "read", "update", "delete", "list"]
        }
        path "identity/group-alias" {
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

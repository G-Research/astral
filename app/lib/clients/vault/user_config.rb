require "set"
module Clients
  class Vault
    module UserConfig
      def config_user(identity, cert)
        sub = identity.sub
        email = identity.email
        policies, metadata = get_entity_data(sub)
        client.sys.put_policy(GENERIC_CERT_POLICY_NAME, generic_cert_policy)
        policies.append(GENERIC_CERT_POLICY_NAME).to_set.to_a
        put_entity(sub, policies, metadata)
        put_entity_alias(sub, email , "oidc")
      end

      private

      def get_entity_data(sub)
        entity = read_entity(sub)
        if entity.nil?
          [[], nil]
        else
          [entity.data[:policies], entity.data[:metadata]]
        end
      end

      GENERIC_CERT_POLICY_NAME = "astral-generic-cert-policy"

      def generic_cert_policy
        policy = <<-EOH
               path "#{cert_path}" {
                 capabilities = ["create", "update"]
               }

               path "#{intermediate_ca_mount}/revoke" {
                 capabilities = ["update"]
               }
        EOH
      end
    end
  end
end
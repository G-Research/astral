require "set"
module Clients
  class Vault
    module UserConfig
      def config_user(identity, cert)
        sub = identity.sub
        email = identity.email
        entity = read_entity(sub)
        if entity.nil?
          policies = []
          metadata = nil
        else
          policies = entity.data[:policies]
          metadata = entity.data[:metadata]
        end
        policy = create_cert_policy(cert)
        client.sys.put_policy(policy_name(sub), policy)
        client.sys.put_policy(GENERIC_CERT_POLICY_NAME, generic_cert_policy)
        policies.append(policy_name(sub)).append(GENERIC_CERT_POLICY_NAME).to_set.to_a
        put_entity(sub, policies, metadata)
        put_entity_alias(sub, email , "oidc")
      end

      private

      def create_cert_policy(cert)
        "path \"#{intermediate_ca_mount}/cert/#{serial_number(cert)}\" {
          capabilities = [\"read\"]
        }"
      end

      def serial_number(cert)
        cert[:serial_number]
      end

      def policy_name(sub)
        "astral-#{sub}-cert-policy"
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
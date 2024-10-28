require "set"
module Clients
  class Vault
    module UserConfig
      def config_user(identity, cert)
        sub = identity.sub
        email = identity.email
        policies, metadata = get_entity_data(sub)
        policies.append(Certificate::GENERIC_CERT_POLICY_NAME).to_set.to_a
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
    end
  end
end
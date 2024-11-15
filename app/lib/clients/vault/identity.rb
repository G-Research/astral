module Clients
  class Vault
    module Identity
      def put_entity(name, policies, metadata = {})
        Domain.with_advisory_lock(name) do
          original_policies, original_metadata = get_entity_data(name)
          policies = (policies || []) + original_policies
          metadata = (metadata || {}).merge((original_metadata || {}))
          write_identity("identity/entity", name, policies, metadata)
        end
      end

      def put_group(name, policies, metadata = {})
        Domain.with_advisory_lock(name) do
          original_policies, original_metadata = get_group_data(name)
          policies = (policies || []) + original_policies
          metadata = metadata.merge((original_metadata || {}))
          write_identity("identity/group", name, policies.uniq, metadata, type: "external")
        end
      end

      def get_group_data(name)
        get_identity_data("identity/group/name/#{name}")
      end

      def read_entity(sub)
        read_identity("identity/entity/name/#{sub}")
      end

      def get_entity_data(sub)
        get_identity_data("identity/entity/name/#{sub}")
      end

      def delete_entity(name)
        client.logical.delete("identity/entity/name/#{name}")
      end

      def read_group_alias(entity_name, alias_name)
        id = read_entity_alias_id(entity_name, alias_name)
        client.logical.read("identity/entity-alias/id/#{id}")
      end

      private

      def write_identity(path, name, policies, metadata, extra_params = {})
        params = {
          name: name,
          policies: policies,
          metadata: metadata
        }.merge(extra_params)

        client.logical.write(path, params)
      end

      def read_identity(path)
        client.logical.read(path)
      end

      def get_identity_data(path)
        identity = read_identity(path)
        if identity.nil?
          [ [], {} ]
        else
          [ identity.data[:policies], identity.data[:metadata] ]
        end
      end
    end
  end
end

module Clients
  class Vault
    module Identity
      def put_entity(name, policies)
        write_identity(path: "identity/entity",
                       name: name,
                       policies: policies,
                       extra_params: [ :metadata, :disabled ])
      end

      def put_group(name, policies)
        write_identity(path: "identity/group",
                       name: name,
                       policies: policies,
                       extra_params: [ :metadata, :type, :member_group_ids, :member_entity_ids ],
                       defaults: { type: "external" })
      end

      def read_entity(sub)
        read_identity("identity/entity/name/#{sub}")
      end

      def get_entity_data(sub)
        get_identity_data("identity/entity/name/#{sub}")
      end

      def get_group_data(name)
        get_identity_data("identity/group/name/#{name}")
      end

      def delete_entity(name)
        client.logical.delete("identity/entity/name/#{name}")
      end

      private

      def write_identity(path:, name:, policies:, defaults: {}, extra_params: [], merge_policies: true)
        full_path = "#{path}/name/#{name}"
        Domain.with_advisory_lock(full_path) do
          identity = read_identity(full_path)
          policies = (policies || []) + (identity&.data&.fetch(:policies) || []) if merge_policies
          params = defaults.
                     merge({
                             name: name,
                             policies: policies.uniq
                           }).
                     merge((identity&.data || {}).
                             slice(*extra_params)).
                     compact
          client.logical.write(path, params)
        end
      end

      def read_identity(path)
        client.logical.read(path)
      end

      def get_identity_data(path)
        identity = read_identity(path)
        if identity
          [ identity.data[:policies], identity.data[:metadata] ]
        else
          [ [], {} ]
        end
      end
    end
  end
end

module Clients
  class Vault
    module Entity
      def put_entity(name, policies, metadata = {})
        client.logical.write("identity/entity",
                             name: name,
                             policies: policies,
                             metadata: metadata)
      end

      def put_group(name, policies, auth_method = "oidc", metadata = {})
        Domain.with_advisory_lock(name) do
          original_policies, original_metadata = get_group_data(name)
          policies = (policies || []) + original_policies
          metadata = metadata.merge((original_metadata || {}))
          client.logical.write("identity/group",
                               {
                                 name: name,
                                 type: "external",
                                 policies: policies.uniq,
                                 metadata: metadata
                               }
                              )

          # create group_alias if needed
          unless original_policies.present?
                   auth_sym = "#{auth_method}/".to_sym
                   accessor = client.logical.read("/sys/auth").data[auth_sym][:accessor]
                   group = read_group(name)
                   client.logical.write("identity/group-alias",
                                        {
                                          name: name,
                                          mount_accessor: accessor,
                                          canonical_id: group.data[:id]
                                        }
                                       )
          end
        end
      end

      def read_group(name)
        client.logical.read("identity/group/name/#{name}")
      end

      def get_group_data(name)
        group = read_group(name)
        if group.nil?
          [ [], {} ]
        else
          [ group.data[:policies], group.data[:metadata] ]
        end
      end

      def read_entity(name)
        client.logical.read("identity/entity/name/#{name}")
      end

      def delete_entity(name)
        client.logical.delete("identity/entity/name/#{name}")
      end

      def get_entity_data(sub)
        entity = read_entity(sub)
        if entity.nil?
          [ [], {} ]
        else
          [ entity.data[:policies], entity.data[:metadata] ]
        end
      end

      def read_group_alias(entity_name, alias_name)
        id = read_entity_alias_id(entity_name, alias_name)
        client.logical.read("identity/entity-alias/id/#{id}")
      end
    end
  end
end

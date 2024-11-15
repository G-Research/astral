module Clients
  class Vault
    module IdentityAlias
      def put_entity_alias(entity_name, alias_name, auth_method)
        write_identity_alias("entity", entity_name, alias_name, auth_method)
      end

      def put_group_alias(group_name, auth_method)
        write_identity_alias("group", group_name, group_name, auth_method)
      end

      def read_group_alias(group_name, alias_name)
        id = read_entity_alias_id(group_name, alias_name)
        client.logical.read("identity/entity-alias/id/#{id}")
      end

      def read_entity_alias_id(entity_name, alias_name)
        e = read_entity(entity_name)
        if e.nil?
          raise "no such entity #{entity_name}"
        end
        aliases = e.data[:aliases]
        a = aliases.find { |a| a[:name] == alias_name }
        if a.nil?
          raise "no such alias #{alias_name}"
        end
        a[:id]
      end

      def read_entity_alias(entity_name, alias_name)
        id = read_entity_alias_id(entity_name, alias_name)
        client.logical.read("identity/entity-alias/id/#{id}")
      end

      def delete_entity_alias(entity_name, alias_name)
        id = read_entity_alias_id(entity_name, alias_name)
        client.logical.delete("identity/entity-alias/id/#{id}")
      end

      private

      def write_identity_alias(type, identity_name, alias_name  auth_method)
        auth_sym = "#{auth_method}/".to_sym
        accessor = client.logical.read("/sys/auth")
        accessor = accessor.data[auth_sym][:accessor]
        alias_path = "identity/#{type}-alias/name/#{alias_name}"
        result = client.logical.read(alias_path)

        unless result
          identity = read_identity("identity/#{type}/name/#{identity_name}")
          client.logical.write("identity/#{type}-alias",
                               {
                                 name: name,
                                 mount_accessor: accessor,
                                 canonical_id: identity.data[:id]
                               }
                              )
        end
      rescue => e
        # if redundant just ignore
        if /already in use/.match? e.to_s
          return
        end
        raise e
      end
    end
  end
end

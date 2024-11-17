module Clients
  class Vault
    module IdentityAlias
      def put_entity_alias(entity_name, alias_name, auth_method)
        write_identity_alias("entity", entity_name, alias_name, auth_method)
      end

      def put_group_alias(group_name, alias_name, auth_method)
        write_identity_alias("group", group_name, alias_name, auth_method)
      end

      def read_entity_alias(entity_name, alias_name, auth_path)
        read_identity_alias("entity", entity_name, alias_name, auth_path)
      end

      def read_group_alias(group_name, alias_name, auth_path)
        read_identity_alias("group", group_name, alias_name, auth_path)
      end

      def delete_entity_alias(entity_name, alias_name, auth_path)
        identity = client.logical.read("identity/entity/name/#{entity_name}")
        if identity.nil?
          raise "no such #{type} #{identity_name}"
        end
        id = find_identity_alias_id(identity, alias_name, auth_path)
        if id.nil?
          raise "no such alias #{alias_name}"
        end
        client.logical.delete("identity/entity-alias/id/#{id}")
      end

      private

      def find_identity_alias_id(identity, alias_name, auth_path)
        aliases = identity.data[:aliases] || [ identity.data[:alias] ]
        a = find_alias(aliases, alias_name, auth_path)
        a&.fetch(:id)
      end

      def find_alias(aliases, name, auth_path)
        aliases&.find { |a| a[:name] == name && a[:mount_path] == "auth/#{auth_path}/" }
      end

      def read_identity_alias(type, identity_name, alias_name, auth_path)
        identity = client.logical.read("identity/#{type}/name/#{identity_name}")
        if identity.nil?
          raise "no such #{type} #{identity_name}"
        end
        id = find_identity_alias_id(identity, alias_name, auth_path)
        if id.nil?
          raise "no such alias #{alias_name}"
        end
        client.logical.read("identity/#{type}-alias/id/#{id}")
      end

      def write_identity_alias(type, identity_name, alias_name, auth_method)
        auth_sym = "#{auth_method}/".to_sym
        accessor = client.logical.read("/sys/auth")
        accessor = accessor.data[auth_sym][:accessor]

        identity = client.logical.read("identity/#{type}/name/#{identity_name}")
        if identity.nil?
          raise "no such #{type} #{identity_name}"
        end
        aliases = (identity.data[:aliases] || [ identity.data[:alias] ])
        identity_alias = find_alias(aliases, alias_name, "oidc")
        # only create alias when not existant
        unless identity_alias
          client.logical.write("identity/#{type}-alias",
                               {
                                 name: alias_name,
                                 mount_accessor: accessor,
                                 canonical_id: identity.data[:id]
                               }
                              )
        end
      end
    end
  end
end

module Clients
  class Vault
    module IdentityAlias
      def put_entity_alias(entity_name, alias_name, auth_method)
        write_identity_alias("entity", entity_name, alias_name, auth_method)
      end

      def put_group_alias(group_name, auth_method)
        write_identity_alias("group", group_name, group_name, auth_method)
      end


      def read_entity_alias(entity_name, alias_name, auth_path)
        id = find_identity_alias_id("entity", entity_name, alias_name, auth_path)
        client.logical.read("identity/entity-alias/id/#{id}")
      end

      def delete_entity_alias(entity_name, alias_name, auth_path)
        id = find_identity_alias_id("entity", entity_name, alias_name, auth_path)
        client.logical.delete("identity/entity-alias/id/#{id}")
      end

      private

      def find_identity_alias_id(type, identity_name, alias_name, auth_path)
        e = read_identity("identity/#{type}/name/#{identity_name}")
        if e.nil?
          raise "no such #{type} #{identity_name}"
        end
        aliases = e.data[:aliases]
        a = find_alias(aliases, alias_name, auth_path)
        a&.fetch(:id)
      end

      def find_alias(aliases, name, auth_path)
        aliases&.find { |a| a[:name] == name && a[:mount_path] == "auth/#{auth_path}/" }
      end

      def write_identity_alias(type, identity_name, alias_name, auth_method)
        auth_sym = "#{auth_method}/".to_sym
        accessor = client.logical.read("/sys/auth")
        accessor = accessor.data[auth_sym][:accessor]

        id = find_identity_alias_id(type, identity_name, alias_name, "oidc")
        # only create alias when not existant
        unless id
          identity = read_identity("identity/#{type}/name/#{identity_name}")
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

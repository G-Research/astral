module Clients
  class Vault
    class << self
      def put_entity_alias(entity_name, alias_name, auth_method)
        e = read_entity(entity_name)
        if e.nil?
          raise "no such entity #{entity_name}"
        end
        canonical_id = e.data[:id]
        auth_sym = "#{auth_method}/".to_sym
        accessor = client.logical.read("/sys/auth").data[auth_sym][:accessor]
        client.logical.write("identity/entity-alias",
                             name: alias_name,
                             canonical_id: canonical_id,
                             mount_accessor: accessor)
      end

      def read_entity_alias_id(entity_name, alias_name)
        e = read_entity(entity_name)
        if e.nil?
          raise "no such entity #{entity_name}"
        end
        aliases = e.data[:aliases]
        a = aliases.find { |a| a[:name] == alias_name}
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
    end
  end
end

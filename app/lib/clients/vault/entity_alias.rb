module Clients
  class Vault
    class << self
      # auth_path e.g. "oidc/"
      def put_entity_alias(entity_name, alias_name, auth_path)
        e = read_entity(entity_name)
        if e.nil?
          raise "no such entity #{entity_name}"
        end
        canonical_id = e.data[:id]
        accessor = client.logical.read("/sys/auth").data[auth_path.to_sym][:accessor]
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
        client.logical.read(
          "identity/entity-alias/id/#{read_entity_alias_id(entity_name, alias_name)}")
      end

      def delete_entity_alias(entity_name, alias_name)
        client.logical.delete(
          "identity/entity-alias/id/#{read_entity_alias_id(entity_name, alias_name)}")
      end
    end
  end
end

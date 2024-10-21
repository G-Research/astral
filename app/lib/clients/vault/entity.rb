module Clients
  class Vault
    module Entity
      def put_entity(name, policies)
        client.logical.write("identity/entity",
                             name: name,
                             policies: policies)
      end

      def read_entity(name)
        client.logical.read("identity/entity/name/#{name}")
      end

      def delete_entity(name)
        client.logical.delete("identity/entity/name/#{name}")
      end
    end
  end
end

module Clients
  class Vault
    class << self
      def put_entity(opts)
        client.logical.write("identity/entity", opts)
      end
      def read_entity(name)
        client.logical.read("identity/entity/name/" + name.to_s)
      end
    end
  end
end

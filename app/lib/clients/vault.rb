module Clients
  class Vault
    extend Clients::Vault::Certificate
    extend Clients::Vault::KeyValue
    extend Clients::Vault::Policy
    extend Clients::Vault::Entity
    extend Clients::Vault::EntityAlias

    class_attribute :token

    class << self
      private

      def client
        ::Vault::Client.new(
          address: address,
          token: token
        )
      end

      def address
        Config[:vault_addr]
      end

      def enable_engine(mount, type)
        client.sys.mount(mount, type, "#{type} secrets engine")
      end
    end
  end
end

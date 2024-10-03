module Clients
  class Vault
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

  require_relative "vault/key_value"
  require_relative "vault/certificate"
  require_relative "vault/policy"
  require_relative "vault/entity"
  require_relative "vault/entity_alias"
end

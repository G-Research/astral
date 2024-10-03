module Clients
  class Vault
    class << self
      private

      def client
        ::Vault::Client.new(
          address: vault_address,
          token: vault_token
        )
      end

      def vault_address
        Config[:vault_addr]
      end

      def vault_token
        Config[:vault_token]
      end

      def enable_engine(mount, type)
        client.sys.mount(mount, type, "#{type} secrets engine")
      end
    end
  end

  require_relative "vault/key_value"
  require_relative "vault/certificate"
end

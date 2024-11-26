module Clients
  class Vault
    extend Clients::Vault::Certificate
    extend Clients::Vault::KeyValue
    extend Clients::Vault::Policy
    extend Clients::Vault::Identity
    extend Clients::Vault::IdentityAlias
    extend Clients::Vault::Oidc

    class_attribute :token

    class << self
      private

      def client
        ::Vault::Client.new(
          address: address,
          token: token,
          ssl_ca_cert: ssl_cert,
          ssl_pem_file: ssl_client_cert,
          ssl_key_file: ssl_client_key
        )
      end

      def address
        Config[:vault_addr]
      end

      def ssl_cert
        Config[:vault_ssl_cert]
      end

      def ssl_client_cert
        Config[:vault_ssl_client_cert]
      end

      def ssl_client_key
        Config[:vault_ssl_client_key]
      end

      def enable_engine(mount, type)
        client.sys.mount(mount, type, "#{type} secrets engine")
      end
    end
  end
end

module Services
  class VaultService
    def initialize
      @client = Vault::Client.new(
        address: Rails.application.config.astral[:vault_addr],
        token: Rails.application.config.astral[:vault_token]
      )
    end

    def get_cert_for(identity)
      # Generate the TLS certificate using the intermediate CA
      tls_cert = @client.logical.write("pki_int/issue/learn",
          common_name: identity[:common_name],
          ttl: Rails.application.config.astral[:cert_ttl],
          ip_sans: identity[:ip_sans],
          format: "pem")
      tls_cert.data
    end
  end
end

module Services
  class VaultService
    def initialize
      @client = Vault::Client.new(
        address: ENV["VAULT_ADDR"],
        token: ENV["VAULT_TOKEN"]
      )
    end

    def new_cert(common_name, ttl)
      # Generate the TLS certificate using the intermediate CA
      tls_cert = @client.logical.write("pki_int/issue/learn",                                      common_name: common_name,
                                      ttl: ttl,
                                      ip_sans: "192.168.1.1",
                                      format: "pem")
      tls_cert.data
    end
  end
end

module Services
  class VaultService
    def initialize
      @client = Vault::Client.new(
        address: ENV["VAULT_ADDR"],
        token: ENV["VAULT_TOKEN"]
      )
    end

    def new_cert(common_name, ttl)
      # Generate the mTLS certificate using the intermediate CA
      mtls_cert = Vault.logical.write("pki-intermediate/issue/client-cert",
                                      common_name: common_name,
                                      ttl: ttl,
                                      ip_sans: "192.168.1.1",
                                      format: "pem")

      # Extract the certificate, private key, and issuing CA chain
      certificate = mtls_cert.data["certificate"]
      private_key = mtls_cert.data["private_key"]
      issuing_ca = mtls_cert.data["issuing_ca"]

      # Print the certificate details
      puts "Certificate:\n#{certificate}"
      puts "Private Key:\n#{private_key}"
      puts "Issuing CA Chain:\n#{issuing_ca}"
      mtls_cert
    end
  end
end

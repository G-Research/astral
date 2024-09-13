module Services
  class VaultService
    class << self
      def issue_cert(cert_issue_request)
        opts = cert_issue_request.attributes
        # Generate the TLS certificate using the intermediate CA
        tls_cert = client.logical.write(Rails.configuration.astral[:vault_cert_path], opts)
        OpenStruct.new tls_cert.data
      end

      private

      def client
        # TODO create a new token for use in the session
        Vault::Client.new(
          address: Rails.configuration.astral[:vault_addr],
          token: Rails.configuration.astral[:vault_token]
        )
      end
    end
  end
end

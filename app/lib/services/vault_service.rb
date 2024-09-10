module Services
  class VaultService
    def initialize
      # TODO create a new token for use in the session
      @client = Vault::Client.new(
        address: Rails.application.configuration.astral[:vault_addr],
        token: Rails.application.configuration.astral[:vault_token]
      )
    end

    def issue_cert(cert_issue_request)
      opts = cert_issue_request.attributes
      # Generate the TLS certificate using the intermediate CA
      tls_cert = @client.logical.write(Rails.application.configuration.astral[:vault_cert_path], opts)
      OpenStruct.new tls_cert.data
    end
  end
end

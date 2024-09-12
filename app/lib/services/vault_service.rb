module Services
  class VaultService
    attr_reader :client

    def initialize
      # TODO create a new token for use in the session
      @client = Vault::Client.new(
        address: Rails.configuration.astral[:vault_addr],
        token: Rails.configuration.astral[:vault_token]
      )
    end

    def issue_cert(cert_issue_request)
      opts = cert_issue_request.attributes
      # Generate the TLS certificate using the intermediate CA
      tls_cert = client.logical.write(Rails.configuration.astral[:vault_cert_path], opts)
      OpenStruct.new tls_cert.data
    end
  end
end

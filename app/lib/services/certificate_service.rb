module Services
  class CertificateService
    def initialize
      # TODO this should select an implementation service based on config
      @impl = VaultService.new
    end

    def get_cert_for(identity, cert_issue_request)
      @impl.get_cert_for(identity, cert_issue_request)
    end
  end
end

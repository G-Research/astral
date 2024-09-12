module Services
  class CertificateService
    attr_reader :impl

    def initialize
      # TODO this should select an implementation service based on config
      @impl = VaultService.new
    end

    def issue_cert(cert_issue_request)
      impl.issue_cert(cert_issue_request)
    end
  end
end

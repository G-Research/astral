module Services
  class CertificateService
    class << self
      def issue_cert(cert_issue_request)
        impl.issue_cert(cert_issue_request)
      end

      private

      def impl
        # TODO this should select an implementation service based on config
        VaultService
      end
    end
  end
end

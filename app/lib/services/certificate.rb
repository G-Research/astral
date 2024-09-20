module Services
  class Certificate
    class << self
      def issue_cert(cert_issue_request)
        impl.issue_cert(cert_issue_request)
      end

      private

      def impl
        # TODO this should select an implementation service based on config
        Clients::Vault
      end
    end
  end
end

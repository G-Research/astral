module Services
  class SecretsService
    class << self
      def issue_cert(cert_issue_request)
        impl.issue_cert(cert_issue_request)
      end

      def kv_read(path)
        impl.kv_read(path)
      end

      def kv_write(path, data)
        impl.kv_write(path, data)
      end

      def kv_delete(path)
        impl.kv_delete(path)
      end

      private

      def impl
        # TODO this should select an implementation service based on config
        VaultService
      end
    end
  end
end

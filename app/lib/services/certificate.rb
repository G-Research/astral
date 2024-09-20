module Services
<<<<<<<< HEAD:app/lib/services/secrets_service.rb
  class SecretsService
========
  class Certificate
>>>>>>>> main:app/lib/services/certificate.rb
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
        Clients::Vault
      end
    end
  end
end

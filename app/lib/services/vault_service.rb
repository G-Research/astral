module Services
  class VaultService
    class << self
      def issue_cert(cert_issue_request)
        opts = cert_issue_request.attributes
        # Generate the TLS certificate using the intermediate CA
        tls_cert = client.logical.write(Rails.configuration.astral[:vault_cert_path], opts)
        OpenStruct.new tls_cert.data
      end

      def kv_read(path)
        client.kv(kv_mount).read(path)
      end

      def kv_write(path, data)
        enable_engine(kv_mount, "kv-v2")
        client.logical.write("#{kv_mount}/#{path}", data)
      end

      def kv_delete(path)
        client.logical.delete("#{kv_mount}/#{path}")
      end

      private

      def client
        # TODO create a new token for the session
        Vault::Client.new(
          address: Rails.configuration.astral[:vault_addr],
          token: Rails.configuration.astral[:vault_token]
        )
      end

      def enable_engine(mount, type)
        unless client.sys.mounts.key?(mount + "/")
          client.sys.mount(mount, type, "#{type} secrets engine")
        else
          puts "#{mount} already enabled."
        end
      rescue Vault::HTTPError => e
        puts "Error enabling #{type} engine: #{e}"
      end

      def kv_mount
        # TODO should this be dynamic based on identity?
        "astralkv"
      end
    end
  end
end

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
        client.logical.write("#{kv_mount}/data/#{path}", data: data)
      end

      def kv_delete(path)
        client.logical.delete("#{kv_mount}/data/#{path}")
      end

      private

      def client
        # TODO create a new token for the session
        Vault::Client.new(
          address: Rails.configuration.astral[:vault_addr],
          token: Rails.configuration.astral[:vault_token]
        )
      end

      def vault_address
        Rails.configuration.astral[:vault_addr]
      end

      def kv_mount
        Rails.configuration.astral[:vault_kv_mount]
      end

      def pki_mount
        Rails.configuration.astral[:vault_pki_mount]
      end
      
      def root_ca_ref
        Rails.configuration.astral[:vault_root_ca_ref]
      end

      def enable_engine(mount, type)
        client.sys.mount(mount, type, "#{type} secrets engine")
      end

      def enable_ca
        # if mount exists, assume configuration is done
        if client.sys.mounts.key?(pki_mount.to_sym)
          return
        end

        # create the mount
        enable_engine(pki_mount, "pki")

        # Generate intermediate CSR
        intermediate_csr = Vault.logical.write("#{pki_mount}/intermediate/generate/internal",
                                               common_name: "astral.internal Intermediate Authority",
                                               issuer_name: "astral-intermediate").data[:csr]

        # Save the intermediate CSR
        File.write("tmp/pki_intermediate.csr", intermediate_csr)

        # Sign the intermediate certificate with the root CA
        intermediate_cert = Vault.logical.write("#{pki_mount}/root/sign-intermediate",
                                                issuer_ref: root_ca_ref,
                                                csr: intermediate_csr,
                                                format: "pem_bundle",
                                                ttl: "43800h").data[:certificate]

        # Save the signed intermediate certificate
        File.write("tmp/intermediate.cert.pem", intermediate_cert)

        # Set the signed intermediate certificate
        Vault.logical.write("#{pki_mount}/intermediate/set-signed", certificate: intermediate_cert)

        # Configure the intermediate CA
        Vault.logical.write("#{pki_mount}/config/cluster",
                            path: "#{vault_address}/v1/#{pki_mount}",
                            aia_path: "#{vault_address}/v1/#{pki_mount}")

        issuer_ref = Vault.logical.read("#{pki_mount}/config/issuers").data[:default]
        Vault.logical.write("#{pki_mount}/roles/astral",
                            issuer_ref: issuer_ref,
                            allow_any_name: true,
                            max_ttl: "720h",
                            no_store: false)

        Vault.logical.write("#{pki_mount}/config/urls",
                            issuing_certificates: "{{cluster_aia_path}}/issuer/{{issuer_id}}/der",
                            crl_distribution_points: "{{cluster_aia_path}}/issuer/{{issuer_id}}/crl/der",
                            ocsp_servers: "{{cluster_path}}/ocsp",
                            enable_templating: true)
      rescue Vault::HTTPError => e
        Rails.logger.error "Unable to configure intermediate_cert: #{e}"
      end

      
    end
  end
end

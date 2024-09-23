module Clients
  class Vault
    class << self
      def issue_cert(cert_issue_request)
        configure_pki
        opts = cert_issue_request.attributes
        # Generate the TLS certificate using the intermediate CA
        tls_cert = client.logical.write(cert_path, opts)
        OpenStruct.new tls_cert.data
      end

      def configure_pki
        enable_ca
      end

      private

      def intermediate_ca_mount
        "pki_astral"
      end

      def cert_path
        "#{intermediate_ca_mount}/issue/astral"
      end

      def root_ca_ref
        Rails.configuration.astral[:vault_root_ca_ref]
      end

      def root_ca_mount
        Rails.configuration.astral[:vault_root_ca_mount]
      end

      def cert_engine_type
        "pki"
      end

      def enable_ca
        # if mount exists, assume configuration is done
        if client.sys.mounts.key?(intermediate_ca_mount.to_sym)
          return
        end

        # create the mount
        enable_engine(intermediate_ca_mount, cert_engine_type)

        # Generate intermediate CSR
        intermediate_csr = client.logical.write("#{intermediate_ca_mount}/intermediate/generate/internal",
                                                common_name: "astral.internal Intermediate Authority",
                                                issuer_name: "astral-intermediate").data[:csr]

        # Save the intermediate CSR
        File.write("tmp/pki_intermediate.csr", intermediate_csr)

        # Sign the intermediate certificate with the root CA
        intermediate_cert = client.logical.write("#{root_ca_mount}/root/sign-intermediate",
                                                 issuer_ref: root_ca_ref,
                                                 csr: intermediate_csr,
                                                 format: "pem_bundle",
                                                 ttl: "43800h").data[:certificate]

        # Save the signed intermediate certificate
        File.write("tmp/intermediate.cert.pem", intermediate_cert)

        # Set the signed intermediate certificate
        client.logical.write("#{intermediate_ca_mount}/intermediate/set-signed", certificate: intermediate_cert)

        # Configure the intermediate CA
        client.logical.write("#{intermediate_ca_mount}/config/cluster",
                             path: "#{vault_address}/v1/#{intermediate_ca_mount}",
                             aia_path: "#{vault_address}/v1/#{intermediate_ca_mount}")

        # Configure the role for issuing certs
        issuer_ref = client.logical.read("#{intermediate_ca_mount}/config/issuers").data[:default]
        client.logical.write("#{intermediate_ca_mount}/roles/astral",
                             issuer_ref: issuer_ref,
                             allow_any_name: true,
                             max_ttl: "720h",
                             no_store: false)

        client.logical.write("#{intermediate_ca_mount}/config/urls",
                             issuing_certificates: "{{cluster_aia_path}}/issuer/{{issuer_id}}/der",
                             crl_distribution_points: "{{cluster_aia_path}}/issuer/{{issuer_id}}/crl/der",
                             ocsp_servers: "{{cluster_path}}/ocsp",
                             enable_templating: true)
      rescue ::Vault::HTTPError => e
        Rails.logger.error "Unable to configure intermediate_cert: #{e}"
      end
    end
  end
end

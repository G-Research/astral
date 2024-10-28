module Clients
  class Vault
    module Certificate
      def issue_cert(cert_issue_request)
        opts = cert_issue_request.attributes
        # Generate the TLS certificate using the intermediate CA
        tls_cert = client.logical.write(cert_path, opts)
        OpenStruct.new tls_cert.data
      end

      def configure_pki
        # if intermediate mount exists, assume configuration is done
        return if client.sys.mounts.key?(intermediate_ca_mount.to_sym)
        configure_root_ca if create_root?
        enable_ca
        sign_cert
        configure_ca
        create_generic_cert_policy
      end

      GENERIC_CERT_POLICY_NAME = "astral-generic-cert-policy"

      private

      def intermediate_ca_mount
        "pki_astral"
      end

      def cert_path
        "#{intermediate_ca_mount}/issue/astral"
      end

      def create_root?
        create_root_config = Config[:vault_create_root]
        !!ActiveModel::Type::Boolean.new.cast(create_root_config)
      end

      def root_ca_ref
        Config[:vault_root_ca_ref]
      end

      def root_ca_mount
        Config[:vault_root_ca_mount]
      end

      def cert_engine_type
        "pki"
      end

      def enable_ca
        # create the intermediate mount
        enable_engine(intermediate_ca_mount, cert_engine_type)
      end

      def configure_root_ca
        return if client.sys.mounts.key?(root_ca_mount.to_sym)

        # enable engine
        enable_engine(root_ca_mount, cert_engine_type)

        # generate root certificate
        root_cert = client.logical.write("#{root_ca_mount}/root/generate/internal",
                                         common_name: "astral.internal",
                                         issuer_name: root_ca_ref,
                                         ttl: "87600h").data[:certificate]
        # save the root certificate
        File.write("tmp/#{root_ca_mount}.crt", root_cert)

        client.logical.write("#{root_ca_mount}/config/cluster",
                             path: "#{address}/v1/#{root_ca_mount}",
                             aia_path: "#{address}/v1/#{root_ca_mount}")

        client.logical.write("#{root_ca_mount}/config/urls",
                             issuing_certificates: "{{cluster_aia_path}}/issuer/{{issuer_id}}/der",
                             crl_distribution_points: "{{cluster_aia_path}}/issuer/{{issuer_id}}/crl/der",
                             ocsp_servers: "{{cluster_path}}/ocsp",
                             enable_templating: true)
      end

      def sign_cert
        # generate intermediate CSR
        intermediate_csr = client.logical.write("#{intermediate_ca_mount}/intermediate/generate/internal",
                                                common_name: "astral.internal Intermediate Authority",
                                                issuer_name: "astral-intermediate").data[:csr]

        # save the intermediate CSR
        File.write("tmp/#{intermediate_ca_mount}.csr", intermediate_csr)

        # sign the intermediate certificate with the root CA
        intermediate_cert = client.logical.write("#{root_ca_mount}/root/sign-intermediate",
                                                 issuer_ref: root_ca_ref,
                                                 csr: intermediate_csr,
                                                 format: "pem_bundle",
                                                 ttl: "43800h").data[:certificate]

        # save the signed intermediate certificate
        File.write("tmp/#{intermediate_ca_mount}.crt", intermediate_cert)

        # set the signed intermediate certificate
        client.logical.write("#{intermediate_ca_mount}/intermediate/set-signed", certificate: intermediate_cert)
      end

      def configure_ca
        # Configure the intermediate CA
        client.logical.write("#{intermediate_ca_mount}/config/cluster",
                             path: "#{address}/v1/#{intermediate_ca_mount}",
                             aia_path: "#{address}/v1/#{intermediate_ca_mount}")

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
      end

      def create_generic_cert_policy
        client.sys.put_policy(GENERIC_CERT_POLICY_NAME, generic_cert_policy)
      end

      def generic_cert_policy
        policy = <<-EOH

               path "#{cert_path}" {
                 capabilities = ["create", "update"]
               }

               path "#{intermediate_ca_mount}/revoke-with-key" {
                 capabilities = ["update"]
               }
        EOH
      end
    end
  end
end

require "rake"
require "vault"
require "json"

# Helper method to enable PKI engine for dev environment
def enable_pki(path, max_ttl)
  unless Vault.sys.mounts.key?(path + "/")
    Vault.sys.mount(path, "pki", "PKI Secrets Engine")
  else
    puts "#{path} already enabled."
  end
end

# Define Rake tasks
namespace :vault do
  desc "Setup PKI root and intermediate certificates"
  task :setup do
    Vault.address = ENV["VAULT_ADDRESS"]
    Vault.token = ENV["VAULT_TOKEN"]
    Rake::Task["vault:enable_root_pki"].invoke
    Rake::Task["vault:configure_root_pki"].invoke
    Rake::Task["vault:enable_intermediate_pki"].invoke
    Rake::Task["vault:configure_intermediate_pki"].invoke
  end

  desc "Enable and configure root PKI"
  task :enable_root_pki do
    enable_pki("pki", "87600h")

    # Generate root certificate
    root_cert = Vault.logical.write("pki/root/generate/internal",
                                    common_name: "astral.internal",
                                    issuer_name: "root-2024",
                                    ttl: "87600h").data["certificate"]

    # Save the root certificate
    File.write("root_2024_ca.crt", root_cert)
  end

  desc "Configure root PKI"
  task :configure_root_pki do
    Vault.logical.write("pki/config/cluster",
                        path: "http://10.1.10.100:8200/v1/pki",
                        aia_path: "http://10.1.10.100:8200/v1/pki")

    Vault.logical.write("pki/roles/2023-servers",
                        allow_any_name: true,
                        no_store: false)

    Vault.logical.write("pki/config/urls",
                        issuing_certificates: "{{cluster_aia_path}}/issuer/{{issuer_id}}/der",
                        crl_distribution_points: "{{cluster_aia_path}}/issuer/{{issuer_id}}/crl/der",
                        ocsp_servers: "{{cluster_path}}/ocsp",
                        enable_templating: true)
  end

  desc "Enable and configure intermediate PKI"
  task :enable_intermediate_pki do
    enable_pki("pki_int", "43800h")

    # Generate intermediate CSR
    intermediate_csr = Vault.logical.write("pki_int/intermediate/generate/internal",
                                           common_name: "astral.internal Intermediate Authority",
                                           issuer_name: "learn-intermediate").data["csr"]

    # Save the intermediate CSR
    File.write("pki_intermediate.csr", intermediate_csr)

    # Sign the intermediate certificate with the root CA
    intermediate_cert = Vault.logical.write("pki/root/sign-intermediate",
                                            issuer_ref: "root-2024",
                                            csr: intermediate_csr,
                                            format: "pem_bundle",
                                            ttl: "43800h").data["certificate"]

    # Save the signed intermediate certificate
    File.write("intermediate.cert.pem", intermediate_cert)

    # Set the signed intermediate certificate
    Vault.logical.write("pki_int/intermediate/set-signed", certificate: intermediate_cert)
  end

  desc "Configure intermediate PKI"
  task :configure_intermediate_pki do
    Vault.logical.write("pki_int/config/cluster",
                        path: "http://10.1.10.100:8200/v1/pki_int",
                        aia_path: "http://10.1.10.100:8200/v1/pki_int")

    issuer_ref = Vault.logical.read("pki_int/config/issuers").data["default"]
    Vault.logical.write("pki_int/roles/learn",
                        issuer_ref: issuer_ref,
                        allow_any_name: true,
                        max_ttl: "720h",
                        no_store: false)

    Vault.logical.write("pki_int/config/urls",
                        issuing_certificates: "{{cluster_aia_path}}/issuer/{{issuer_id}}/der",
                        crl_distribution_points: "{{cluster_aia_path}}/issuer/{{issuer_id}}/crl/der",
                        ocsp_servers: "{{cluster_path}}/ocsp",
                        enable_templating: true)
  end
end

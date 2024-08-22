require "rake"
require "vault"
require "json"

# Define Rake tasks
namespace :vault do
  desc "Setup PKI root and intermediate certificates"
  task :setup do
    unless Rails.env.development?
      raise "This task should only be used in development"
    end
    Vault.address = ENV["VAULT_ADDR"]
    Vault.token = ENV["VAULT_TOKEN"]
    ensure_root_cert
    configure_root_cert
    ensure_intermediate_cert
    configure_intermediate_cert
  end
end

# Helper methods
def enable_pki(path, max_ttl)
  unless Vault.sys.mounts.key?(path + "/")
    Vault.sys.mount(path, "pki", "PKI Secrets Engine")
  else
    puts "#{path} already enabled."
  end
rescue Vault::HTTPError => e
  puts "Error enabling pki, already enabled?: #{e}"
end

def ensure_root_cert
  enable_pki("pki", "87600h")

  # Generate root certificate
  root_cert = Vault.logical.write("pki/root/generate/internal",
                                  common_name: "astral.internal",
                                  issuer_name: "root-2024",
                                  ttl: "87600h").data[:certificate]

  # Save the root certificate
  File.write("tmp/root_2024_ca.crt", root_cert)
rescue Vault::HTTPError => e
  puts "Error enabling root pki, already enabled?: #{e}"
end

def configure_root_cert
  Vault.logical.write("pki/config/cluster",
                      path: "#{ENV["VAULT_ADDR"]}/v1/pki",
                      aia_path: "#{ENV["VAULT_ADDR"]}/v1/pki")

  Vault.logical.write("pki/roles/2024-servers",
                      allow_any_name: true,
                      no_store: false)

  Vault.logical.write("pki/config/urls",
                      issuing_certificates: "{{cluster_aia_path}}/issuer/{{issuer_id}}/der",
                      crl_distribution_points: "{{cluster_aia_path}}/issuer/{{issuer_id}}/crl/der",
                      ocsp_servers: "{{cluster_path}}/ocsp",
                      enable_templating: true)
rescue Vault::HTTPError => e
  puts "Error configuring root pki, already enabled?: #{e}"
end

def ensure_intermediate_cert
  enable_pki("pki_int", "43800h")

  # Generate intermediate CSR
  intermediate_csr = Vault.logical.write("pki_int/intermediate/generate/internal",
                                         common_name: "astral.internal Intermediate Authority",
                                         issuer_name: "learn-intermediate").data[:csr]

  # Save the intermediate CSR
  File.write("tmp/pki_intermediate.csr", intermediate_csr)

  # Sign the intermediate certificate with the root CA
  intermediate_cert = Vault.logical.write("pki/root/sign-intermediate",
                                          issuer_ref: "root-2024",
                                          csr: intermediate_csr,
                                          format: "pem_bundle",
                                          ttl: "43800h").data[:certificate]

  # Save the signed intermediate certificate
  File.write("tmp/intermediate.cert.pem", intermediate_cert)

  # Set the signed intermediate certificate
  Vault.logical.write("pki_int/intermediate/set-signed", certificate: intermediate_cert)
rescue Vault::HTTPError => e
  puts "Error enabling intermediate pki, already enabled?: #{e}"
end

def configure_intermediate_cert
  Vault.logical.write("pki_int/config/cluster",
                      path: "#{Vault.address}/v1/pki_int",
                      aia_path: "#{Vault.address}/v1/pki_int")

  issuer_ref = Vault.logical.read("pki_int/config/issuers").data[:default]
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
rescue Vault::HTTPError => e
  puts "Error configuring intermediate pki, already enabled?: #{e}"
end

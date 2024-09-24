require "rake"
require "vault"
require "json"

# Define Rake tasks
namespace :vault do
  desc "Setup PKI root certificate authority"
  task :setup do
    unless Rails.env.development?
      raise "This task should only be used in development"
    end
    Vault.address = ENV["VAULT_ADDR"]
    Vault.token = ENV["VAULT_TOKEN"]
    ensure_root_cert
    configure_root_cert
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
  enable_pki(root_mount, "87600h")

  # Generate root certificate
  root_cert = Vault.logical.write("pki/root/generate/internal",
                                  common_name: "astral.internal",
                                  issuer_name: root_issuer_name,
                                  ttl: "87600h").data[:certificate]

  # Save the root certificate
  File.write("tmp/#{root_issuer_name}.crt", root_cert)
rescue Vault::HTTPError => e
  puts "Error enabling root pki, already enabled?: #{e}"
end

def configure_root_cert
  Vault.logical.write("#{root_mount}/config/cluster",
                      path: "#{ENV["VAULT_ADDR"]}/v1/#{root_mount}",
                      aia_path: "#{ENV["VAULT_ADDR"]}/v1/#{root_mount}")

  Vault.logical.write("#{root_mount}/roles/2024-servers",
                      allow_any_name: true,
                      no_store: false)

  Vault.logical.write("#{root_mount}/config/urls",
                      issuing_certificates: "{{cluster_aia_path}}/issuer/{{issuer_id}}/der",
                      crl_distribution_points: "{{cluster_aia_path}}/issuer/{{issuer_id}}/crl/der",
                      ocsp_servers: "{{cluster_path}}/ocsp",
                      enable_templating: true)
rescue Vault::HTTPError => e
  puts "Error configuring root pki: #{e}"
end

def root_issuer_name
  ENV["VAULT_ROOT_CA_REF"]
end

def root_mount
  ENV["VAULT_ROOT_CA_MOUNT"]
end

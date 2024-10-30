require "rake"

# Rake tasks for making a vault cert
namespace :configure do
  desc "Make Vault, Astral, and OIDC provider certs"
  task ssl: [ :vault_ssl, :astral_ssl, :oidc_provider_ssl ]

  desc "Make the server cert for vault"
  task :vault_ssl do
    keygen("vault")
  end

  desc "Make the server cert for astral"
  task :astral_ssl do
    keygen("astral")
  end

  desc "Make the server cert for the oidc provider"
  task :oidc_provider_ssl do
    keygen("oidc_provider")
  end

  private

  def keygen(name)
    san_param_file = "/tmp/san_param_#{name}"
    san_param_content = "subjectAltName=DNS:#{name}"
    File.write(san_param_file, san_param_content)
    %x(
      openssl req -new -newkey rsa:4096 -nodes \
        -keyout cert/#{name}.key -out cert/#{name}.csr \
        -subj "/C=US/ST=Denial/L=Springfield/O=Dis/CN=#{name}" \
        -addext #{san_param_content}
      openssl x509 -req -days 365 -in cert/#{name}.csr \
        -signkey cert/#{name}.key \
        -out cert/#{name}.pem \
        -extfile #{san_param_file}
    )
    puts "SSL key for #{name} created"
  end
end

require "rake"
require "jwt"
require "openssl"
require "json"

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

  desc "Make JWKS and corresponding token"
  task :jwks do
    optional_parameters = { kid: 'my-kid', use: 'sig', alg: 'RS256' }
    jwk = JWT::JWK.new(OpenSSL::PKey::RSA.new(2048), optional_parameters)

    payload = {"sub"=>"john.doe@example.com", "name"=>"John Doe", "iat"=>1516239022,
               "groups"=>["group1", "group2"], "aud"=>"astral"}

    token = JWT.encode(payload, jwk.signing_key, jwk[:alg], kid: jwk[:kid])
    File.write("test/fixtures/files/token.jwks", token)
    puts "wrote token file test/fixtures/files/token.jwks with payload:\n #{payload}"

    jwks_hash = JWT::JWK::Set.new(jwk).export
    File.write("test/fixtures/files/keyset.jwks", jwks_hash.to_json)
    puts "wrote file test/fixtures/files/keyset.jwks with hash:\n #{jwks_hash}"

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

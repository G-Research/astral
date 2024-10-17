require "rake"

# Rake tasks for making a vault cert
namespace :configure do
  desc "Make the server cert for vault"
  task :ssl do
    %x(
      openssl req -new -newkey rsa:4096 -nodes \
        -keyout cert/vault.key -out cert/vault.csr \
        -subj "/C=US/ST=Denial/L=Springfield/O=Dis/CN=vault"
      openssl x509 -req -days 365 -in cert/vault.csr \
        -signkey cert/vault.key \
        -out cert/vault.pem
    )
    puts "SSL key for vault created"
  end
end

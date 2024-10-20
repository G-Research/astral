require "rake"

# Rake tasks for making a vault cert
namespace :configure do
  desc "Make the server cert for vault"
  task :ssl, [:cert_name] do |t, args|
    cert_name = args[:cert_name]
    cert_name = "vault" if cert_name.nil?
    %x(
     echo "subjectAltName=DNS:#{cert_name}" > /tmp/x
     openssl req -new -newkey rsa:4096 -nodes \
        -keyout cert/#{cert_name}.key -out cert/#{cert_name}.csr \
        -subj "/C=US/ST=Denial/L=Springfield/O=Dis/CN=#{cert_name}" \
        -addext "subjectAltName = DNS:#{cert_name}" \

      openssl x509 -req -days 365 -in cert/#{cert_name}.csr \
        -signkey cert/#{cert_name}.key \
        -out cert/#{cert_name}.pem -extfile /tmp/x
    )
    puts "SSL key for #{cert_name} created"
  end
end

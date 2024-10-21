#! /bin/sh
SSL_CERT="${SSL_CERT:-cert/astral.pem}"
SSL_KEY="${SSL_KEY:-cert/astral.key}"

rails s -b "ssl://0.0.0.0:3000?key=${SSL_KEY}&cert=${SSL_CERT}"

#! /bin/sh
ASTRAL_SSL_CERT="${SSL_CERT:-cert/astral.pem}"
ASTRAL_SSL_KEY="${SSL_KEY:-cert/astral.key}"

bin/rails s -b "ssl://0.0.0.0:3000?key=${ASTRAL_SSL_KEY}&cert=${ASTRAL_SSL_CERT}"

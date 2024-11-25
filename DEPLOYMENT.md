# DEPLOYMENT

# Running the prod image (local build):
1) Build the prod image:
```
docker build -t astral:latest .
```
2) Run the prod image:
```
docker run -p 3000:3000 astral:latest
```

A dockerhub image will be available soon!


# Configuration
Astral is configured in `config/astral.yml` -- all availble
configuration options are listed in the `shared` section.
Configuration values can be supplied in this file in the shared or
environmental override sections. Per-environment settings in the
config file (development, test, production) will override the shared
values for that type.

Configuration values can also be supplied as process
environment variables with the same names (but
UPPER_CASE). Environment vars will override any values in the config
file.

Database-specific configuration is found in `config/database.yml`, for
which environment var overrides are setup to use the `DB_` prefix. We
recommend PostgreSQL for all deployments of Astral, but any
Rails-supported database (sqlite, mysql, Oracle, etc) can be used.

## Database encryption
The Astral database can be encrypted, if needed, but requires a bit of setup
and careful retention of a master key. Note that there are potential performance impacts.

The database stores metadata about secrets (ownership and group info) but no actual secrets.

1. First, create encryption keys for the database:
```
rails db:encryption:init
```
Copy the output to your clipboard.

2. Next, create a `credentials.yml.enc` file:
```
EDITOR=vi rails credentials:edit
```
Paste the db encryption key data into this file, save, and exit.

NB, the credentials file is encrypted and is decoded by a key placed in
`config/master.key`. Be sure to save this file, perhaps in a vault secret.

3. Finally, set the following Astral configuration to 'true':
```
   db_encryption: true
```

## SSL/mTLS connections
Astral should be run as an SSL service and set to communicate with Vault via mTLS.

To run Astral with SSL in production, provide the necessary
environment (ASTRAL_SSL_CERT, ASTRAL_SSL_KEY) to the container
environment, and use the `bin/ssl.sh` startup command. Eg:
```
docker run -p 3000:3000 \
-e ASTRAL_SSL_CERT=/certs/cert.pem \
-e ASTRAL_SSL_KEY=/certs/key.key \
-v certs:/certs:cached \
astral:latest bin/ssl.sh
```

To use mTLS with Vault, set the following values in `config/astral.yml` (or environment) to 
encrypt Astral-to-Vault :
```
  vault_ssl_cert:
  vault_ssl_client_cert:
  vault_ssl_client_key:
```

A self-signed server cert for Vault and Astral can
be generated with the following command. Initial placeholder certs
are already provided -- these should not be used in production.
```
rake configure:ssl
```

More likely, you will want to generate certs from your trusted root or
intermediate and mount them into the container certs volume.


## OIDC configuration
Astral endpoints expect a `Bearer` JWT which carries the subject and
group claims of the client identity. The identity provider is external
to Astral, and could be a service such as Auth0 or a self-hosted
solution. Your Vault backend should be configured to use the same OIDC
provider.

# Decoding JWT with signing key
To decode a JWT using a preshared signing key, set the
`jwt_signing_key` parameter in your configuration.

# Decoding JWKS based tokens
To decode JWKS-based tokens, set the astral.yml `jwks_url` parameter to the 
jwks endpoint of your auth provider.

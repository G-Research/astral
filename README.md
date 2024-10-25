# README

Astral is an api-only application intended to simplify certificate
acquisition and secrets storage. Invoking a single endpoint can issue
an mTLS certificate or fetch a secret for applications in your
environment, without any need to configure the underlying PKI or
secrets storage (Vault).

Some features of Astral:

0) Configure Astral-specific Certificate Authority and Key-Value stores in Vault
1) Authenticate requests for cerficates or secrets using a third party
   trusted source (JWT with signing key, eg)
2) For certiciates:
	a) Authorize the request using a Domain Ownership registry, where domain owner 
	   or authorized groups must match the identity of the requesting client
	b) When authorized, obtain a certificate for the common name
3) For secrets:
	a) Create secrets with a policy for reading
	b) Read only when the requesting client identity has the policy.
4) Log all transactions in audit infrastructure (ELK, etc).

# Running in development

This Rails app is most easily run and developed in its devcontainer, which includes Vault
and a Domain Ownership registry (AppRegistry) in the compose environment.

1) Open in devcontainer (automatic in vscode)
2) Launch server using vscode launch config, or in the terminal run:
```
rails s
```
3) POST /certificates to acquire cert (need to provide `common_name` param):
```
curl -X POST http://localhost:3000/certificates \
-H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJqb2huLmRvZUBleGFtcGxlLmNvbSIsIm5hbWUiOiJKb2huIERvZSIsImlhdCI6MTUxNjIzOTAyMiwiZ3JvdXBzIjpbImdyb3VwMSIsImdyb3VwMiJdLCJhdWQiOiJhc3RyYWwifQ.tfRLXmE_eq-piP88_clwPWrYfMAQbCJAeZQI6OFxZSI" \
-H "Content-type: application/json" \
-d "{ \"cert_issue_request\": { \"common_name\": \"example.com\" } }"
```
4) POST and GET /secrets to save and fetch a secret:
```
curl -X POST http://localhost:3000/secrets \
-H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJqb2huLmRvZUBleGFtcGxlLmNvbSIsIm5hbWUiOiJKb2huIERvZSIsImlhdCI6MTUxNjIzOTAyMiwiZ3JvdXBzIjpbImdyb3VwMSIsImdyb3VwMiJdLCJhdWQiOiJhc3RyYWwifQ.tfRLXmE_eq-piP88_clwPWrYfMAQbCJAeZQI6OFxZSI" \
-H "Content-type: application/json" \
-d "{\"secret\": { \"path\":\"some/path\", \"data\": {\"password\": \"s3crit\"} } }"

curl http://localhost:3000/secrets/some/path \
-H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJqb2huLmRvZUBleGFtcGxlLmNvbSIsIm5hbWUiOiJKb2huIERvZSIsImlhdCI6MTUxNjIzOTAyMiwiZ3JvdXBzIjpbImdyb3VwMSIsImdyb3VwMiJdLCJhdWQiOiJhc3RyYWwifQ.tfRLXmE_eq-piP88_clwPWrYfMAQbCJAeZQI6OFxZSI"
```
5) Run the tests from devcontainer terminal:
```
rails test
```

# Running the prod image (local build):
1) Build the prod image:
```
docker build -t astral:latest .
```
2) Run the prod image:
```
docker run -p 3000:3000 astral:latest
```

# Configuration
Astral is configured in `config/astral.yml` -- all availble
configuration options are listed in the `shared` section. Note that
configuration values can be supplied in this file or as process
environment variables with the same names (but
UPPER_CASE). Environment vars will override any values in the config
file.  Per-environment settings in the config file(development, test,
production) will override the shared values for that type.

## Database encryption
The local database can be encrypted if needed, but requires a bit of setup
and careful retention of a master key. Note that there are performance impacts.

1. First, create encryption keys for the database:
```
rails db:encryption:init
```
Copy the output to your clipboard.

2. Next, create a `credentials.yml.enc` file:
```
EDITOR=vi rails credentials:edit
```
Past the db encryption key data into this file, save, and exit.

NB, the credentials file is decoded by a key placed in
`config/master.key`. Be sure to save this file (it is .gitignored)!

3. Finally, set the following Astral configuration to 'true':
```
   db_encryption: true
```

## mTLS connections
Astral can be run as an SSL service and can communicate with Vault via SSL.
Just set the following values in `config/astral.yml` (or environment) to 
encrypt Astral-to-Vault :
```
  vault_ssl_cert:
  vault_ssl_client_cert:
  vault_ssl_client_key:
```

A self-signed server cert for Vault, Astral, and the OIDC provider can be 
generated with the following command, and initial placeholder certs are already provided.
```
rake configure:ssl
```

To use Vault SSL in the devcontainer, edit
`.devcontainer/docker-compose.yml` so that the `app` service has
`VAULT_ADDRESS` of `https://vault:8443`. Client certs can also be
configured -- in which case Vault needs to supplied with a CA for
peer verification.

To use Astral with SSL in production, provide the necessary
environment (ASTRAL_SSL_CERT, ASTRAL_SSL_KEY) to the container
environment, and use the `bin/ssl.sh` startup command. Eg:
```
docker run -p 3000:3000 \
-e ASTRAL_SSL_CERT=/certs/cert.pem \
-e ASTRAL_SSL_KEY=/certs/key.key \
-v certs:/certs:cached \
astral:latest bin/ssl.sh
```

## OIDC configuration
The OIDC modules allow the assignment of a policy to an OIDC user, by
mapping that user's email address to a policy we create.  They work as
follows:

OidcProvider.new.configure creates an OIDC provider
and user on a separate dedicated Vault instance.  The user created has
a username/password/email address, that can be accessed with OIDC auth
from the principal Vault instance.

Clients::Vault::configure_as_oidc_client creates an OIDC
client on our Vault instance.  It connects to that provider just
created.  When a user tries to auth, the client connects to the
provider, which opens up a browser window allowing the user to enter
their username/password.

On success, the provider returns an OIDC token, which includes the
user's email address.

The OIDC client has been configured to map that email address to an
entity in Vault, which has the policy which we want the user to have.

So the mapping goes from the email address on the provider, to the
policy in Vault.

Note that this provider is mainly meant to be used in our dev/test
environment to excercise the client.  In a prod env, a real OIDC
provider would probably be used instead, (by configuring it in
config/astral.yml).

# Logging into Vault with OIDC

The rails test's configure the OIDC initial user, so if the tests pass,
you can invoke the oidc login as follows:

To use SSL in production, provide the necessary environment (SSL_CERT, SSL_KEY) to
the container environment, and use the `bin/ssl.sh` startup command. Eg:
```
  export VAULT_ADDR=http://127.0.0.1:8200; vault login -method=oidc
```

You should do this on your host machine, not in docker.  This will
allow a browser window to open on your host.  When it does, select
"username" option with user test/test.  (That is the username/pw
configured at startup.)

When that succeeds, you should see something like the following in the cli:
```
Success! You are now authenticated
.
identity_policies    ["test@example.com"]
.
.
```

Note that "identity_policies" includes "test@example.com", which is the
policy we created for this user.

To make this work smoothly with the browser, you should add the
following to the /etc/hosts file on your host:

```
  127.0.0.1	oidc_provider
```

Finally, if you restart the docker Vault container, it will recreate
the provider settings, so you will need to clear the browser's
"oidc_provider" cookie.  Otherwise you will see this error:

```
  * Vault login failed. Expired or missing OAuth state.
```



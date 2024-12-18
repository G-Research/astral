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
2) For certificates:
	1) Authorize the request using a Domain Ownership registry, where domain owner 
	   or authorized groups must match the identity of the requesting client
	2) When authorized, obtain a certificate for the common name
3) For secrets:
	1) Create, read, update, and delete secrets with an arbitrary subpath.
	2) Create secrets with read-only groups for consuming.
	2) Owner/producer has full control.
4) Log all transactions in audit table.

# Running in production

See our [deployment guide](DEPLOYMENT.md) for configuration and deployment information.


# Running in development

This Rails app is most easily run and developed in its devcontainer,
which includes Vault, the Postgres database, a Domain Ownership
registry (AppRegistry), and an Oidc Provider in the compose environment.

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

# Decoding JWKS based tokens
To decode JWKS based tokens, set the astral.yml "jwks_url" parameter to the 
jwks endpoint of your auth provider.

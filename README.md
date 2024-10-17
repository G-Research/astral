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

## mTLS connections
Astral can connect to Vault with mTLS. Just
set the following values in `config/astral.yml`:
```
  vault_ssl_cert:
  vault_ssl_client_cert:
  vault_ssl_client_key:
```
A self-signed server cert for Vault can be generated with the following 
command:
```
rake configure:ssl
```

To use SSL in the devcontainer, edit `.devcontainer/docker-compose.yml` so
that the `app` service has `VAULT_ADDRESS` of `https://vault:8443`. 

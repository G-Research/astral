# README

Astral is an api-only application intended to simplify
certificate acquisition for other applications/services. Broadly speaking,
it will: 

1) Authorize the request for cerficate using a third party trusted source (JWT, etc)
2) If authorized, obtain a certificate from PKI CLM (such as Vault/OpenBao)
3) Log this transaction in audit infrastructure (ELK, etc).

# Running

This Rails app is most easily run and developed in its devcontainer.

1) Open in devcontainer
2) Launch server using vscode launch config, or in terminal run:
```
rails s
```
3) POST /certificates to acquire cert in another terminal (need to provide `common_name` param):
```
curl -X POST http://localhost:3000/certificates \
-H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJqb2huLmRvZUBleGFtcGxlLmNvbSIsIm5hbWUiOiJKb2huIERvZSIsImlhdCI6MTUxNjIzOTAyMiwiZ3JvdXBzIjpbImdyb3VwMSIsImdyb3VwMiJdLCJhdWQiOiJhc3RyYWwifQ.tfRLXmE_eq-piP88_clwPWrYfMAQbCJAeZQI6OFxZSI" \
-H "Content-type: application/json" \
-d "{ \"common_name\": \"example.com\" }"
```
4) Run the tests from devcontainer terminal:
```
rails test
```

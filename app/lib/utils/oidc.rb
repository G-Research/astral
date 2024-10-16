class OidcUtils
  class << self
    def redirect_uris
      # use localhost:8250, per: https://developer.hashicorp.com/vault/docs/auth/jwt#redirect-uris
      "http://localhost:8250/oidc/callback"
    end
  end
end

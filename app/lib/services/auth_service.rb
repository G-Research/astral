module Services
  class AuthService
    def initialize
      @domain_ownership_service = DomainOwnershipService.new
    end

    def authenticate!(token)
      identity = decode(token)
      raise AuthError unless identity
      # TODO verify identity with authority?
      identity
    end

    def authorize!(identity, cert_issue_req)
      @domain_ownership_service.authorize!(identity, cert_issue_req)
    end

    private

    def decode(token)
      # Decode a JWT access token using the configured base.
      body = JWT.decode(token, Rails.configuration.astral[:jwt_signing_key])[0]
      Identity.new(body)
    rescue => e
      Rails.logger.warn "Unable to decode token: #{e}"
      nil
    end
  end
end

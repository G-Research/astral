module Services
  class AuthService
    attr_reader :impl

    def initialize
      # TODO this should select an external service impl when needed
    end

    def authenticate!(token)
      identity = decode(token)
      raise AuthError unless identity
      # TODO verify identity with authority?
      identity
    end

    def self.authenticate!(token)
      new.authenticate!(token)
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

module Utils
  class SecretDecoder
    def initialize(secret)
      @secret = secret
    end

    def configured?(config)
      !@secret.nil?
    end

    def decode(token)
      # Decode a JWT access token using the configured base.
      body = JWT.decode(token, Config[:jwt_signing_key])[0]
      Identity.new(body)
    rescue => e
      Rails.logger.warn "Unable to decode token: #{e}"
      nil
    end
  end
end

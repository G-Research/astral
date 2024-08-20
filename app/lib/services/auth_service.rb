module Services
  class AuthService
   def decode(token)
     # Decode a JWT access token using the configured base.
     body = JWT.decode(token, Rails.application.config.astral[:jwt_signing_key])[0]
     HashWithIndifferentAccess.new body
   rescue => e
     Rails.logger.warn "Unable to decode token: #{e}"
     nil
   end

   def authenticate!(token)
     identity = decode(token)
     raise AuthError unless identity
     # TODO verify identity with authority
     identity
   end
  end
end

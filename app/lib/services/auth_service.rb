module Services
  class AuthService
   def decode(jwt_token)
     # Decode a JWT access token using the configured base.
     body = JWT.decode(token, ENV["JWT_TOKEN_BASE"])[0]
     HashWithIndifferentAccess.new body
   rescue
     nil
   end

   def authenticate!(token)
     identity = decode(token)
     # TODO verify identity with authority
     raise AuthError unless identity
     identity
   end
  end
end

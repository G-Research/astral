module Services
  class AuthService
   def decode(jwt_token)
     # Decode a JWT access token using the configured base.
     body = JWT.decode(token, ENV["JWT_TOKEN_BASE"])[0]
     HashWithIndifferentAccess.new body
   rescue
     nil
   end
  end
end

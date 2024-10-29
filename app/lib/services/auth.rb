require 'open-uri'
module Services
  class Auth
    class << self
      def authenticate!(token)
        identity = decode(token)
        raise AuthError unless identity
        # TODO verify identity with authority?
        identity
      end

      private

      def decode(token)
        # Decode a JWT access token using the configured base.
        jwks_hash = URI.open(Config[:jwks_url]) { |f| f.read }
        jwks = JWT::JWK::Set.new(JSON.parse(jwks_hash))
        jwks.filter! {|key| key[:use] == 'sig' }
        algorithms = jwks.map { |key| key[:alg] }.compact.uniq
        body = JWT.decode(token, nil, true, algorithms: algorithms, jwks: jwks)[0]
        Identity.new(body)
      rescue => e
        Rails.logger.warn "Unable to decode token: #{e}"
        nil
      end
    end
  end
end

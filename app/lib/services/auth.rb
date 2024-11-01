module Services
  class Auth
    class << self
      def authenticate!(token)
        identity = Utils::DecoderFactory.get(Config).decode(token)
        raise AuthError unless identity
        # TODO verify identity with authority?
        identity
      end
    end
  end
end

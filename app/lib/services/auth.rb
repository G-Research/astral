require_relative "../utils/decoder_factory"
module Services
  class Auth
    class << self
      def authenticate!(token)
        identity = DecoderFactory.get(Config).decode(token)
        raise AuthError unless identity
        # TODO verify identity with authority?
        identity
      end
    end
  end
end

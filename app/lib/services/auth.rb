require 'decoder_factory'
module Services
  class Auth
    class << self
      def authenticate!(token)
        identity = DecoderFactory.getDecoder(config).decode(token)
        raise AuthError unless identity
        # TODO verify identity with authority?
        identity
      end
    end
  end
end

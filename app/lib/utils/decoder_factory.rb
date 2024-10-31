require_relative "secret_decoder"
require_relative "jwks_decoder"
class DecoderFactory
  cattr_reader :decoders
  class << self
    # Any new decoders should be added here:
    @@decoders = [ JwksDecoder.new(Config[:jwks_url]),
                   SecretDecoder.new(Config[:jwt_signing_key]) ]

    def get(config)
      configured_decoders = getConfiguredDecoders(config)
      if configured_decoders.length != 1
        raise "Exactly one decoder must be configured"
      end
      configured_decoders[0]
    end

    private
    def getConfiguredDecoders(config)
      decoders.filter { |c| c.configured?(config) }
    end
  end
end

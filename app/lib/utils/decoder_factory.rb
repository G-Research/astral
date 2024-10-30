require_relative "secret_decoder"
require_relative "jwks_decoder"
class DecoderFactory
  cattr_reader :decoders
  class << self
    # Any new decoders should be added here:
    @@decoders = [ JwksDecoder.new(Config[:jwks_url]),
                   SecretDecoder.new(Config[:jwt_signing_key]) ]

    def get(config)
      validateConfig(config)
      decoder = decoders.find { |c| c.configured?(config) }
    end

    private
    def validateConfig(config)
      if decoders.filter  { |c| c.configured?(config) } .length != 1
        raise "Exactly one decoder must be configured"
      end
    end
  end
end

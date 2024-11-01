module Utils
  class DecoderFactory
    cattr_reader :decoders
    class << self
      # Any new decoders should be added here:
      @@decoders = [ Utils::JwksDecoder.new(Config[:jwks_url]),
                     Utils::SecretDecoder.new(Config[:jwt_signing_key]) ]

      def get(config)
        configured_decoders = getConfiguredDecoders(config)
        if configured_decoders.length != 1
          raise "Exactly one decoder must be configured"
        end
        configured_decoders.first
      end

      private
      def getConfiguredDecoders(config)
        decoders.filter { |c| c.configured?(config) }
      end
    end
  end
end

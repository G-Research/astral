require_relative "./default_decoder"
require_relative "./jwks_decoder"
class DecoderFactory
  cattr_reader :decoders
  class << self

    # Any new decoders should be added here:
    @@decoders = [JwksDecoder.new(Config[:jwks_url])]

    # Make sure default decoder comes last
    @@decoders.append(DefaultDecoder.new)

    def get(config)
      decoder = decoders.find { |c| c.configured(config) }
    end
  end
end
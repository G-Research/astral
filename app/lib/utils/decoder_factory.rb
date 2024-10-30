require_relative "./default_decoder"
require_relative "./jwks_decoder"
class DecoderFactory
  class << self
    @@default_decoder = DefaultDecoder.new
    # Any new decoders should be added here:
    @@decoders = [JwksDecoder.new(Config[:jwks_url])]

    # Make sure default decoder comes last
    @@decoders.append(@@default_decoder)
    def get(config)
      decoder = decoders.find { |c| c.configured(config) }
    end

    def decoders
      @@decoders
    end
  end
end
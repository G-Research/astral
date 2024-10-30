require_relative "./default_decoder"
require_relative "./jwks_decoder"
class DecoderFactory
  class << self
    @@decoders = [JwksDecoder.new(Config[:jwks_url])]
    @@default_decoder = DefaultDecoder.new
    def get(config)
      decoder = @@decoders.find { |c| c.configured(config) }
      decoder ||= @@default_decoder
    end

    def register(decoder)
      @@decoders.append(decoder)
    end
  end
end
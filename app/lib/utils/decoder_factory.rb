require_relative "./default_decoder"
class DecoderFactory
  class << self
    @@decoders = []
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
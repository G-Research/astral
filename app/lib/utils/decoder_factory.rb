require_relative "./default_decoder"
class DecoderFactory
  class << self
    @@decoders = []
    def getDecoder(config)
      decoderClass = @@decoders.find { |c| c.configured(config) }
      decoderClass ||= DefaultDecoder
      decoderClass.new
    end
    def register(c)
      @@decoders.append(c)
    end
  end
end
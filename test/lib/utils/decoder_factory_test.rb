require "test_helper"

class DecoderFactoryTest < ActiveSupport::TestCase
  test ".get returns configured decoder" do
    decoders = [ UnconfiguredDecoder.new, ConfiguredDecoder.new ]
    Utils::DecoderFactory.stub :decoders, decoders do
      decoder = Utils::DecoderFactory.get({})
      assert decoder.instance_of?(ConfiguredDecoder)
    end
  end

  test ".get recognizes invalid config" do
    decoders = [ ConfiguredDecoder.new, ConfiguredDecoder.new ]
    Utils::DecoderFactory.stub :decoders, decoders do
      assert_raises(
        RuntimeError, "Exactly one decoder must be configured") do
        decoder = Utils::DecoderFactory.get({})
      end
    end
  end

  class ConfiguredDecoder
    def configured?(c) = true
  end

  class UnconfiguredDecoder
    def configured?(c) = false
  end
end

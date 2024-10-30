require "test_helper"
require_relative '../../../app/lib/utils/decoder_factory'
require_relative '../../../app/lib/utils/jwks_decoder'

class DecoderTest < ActiveSupport::TestCase
  test "JwksDecoder returns correct identity" do
    token = File.read("test/fixtures/files/token.jwks")
    identity = JwksDecoder.new("test/fixtures/files/keyset.jwks").decode(token)
    assert_equal "john.doe@example.com", identity.sub
    assert_equal "astral", identity.aud
  end

  test "DefaultDecoder returns correct identity" do
    identity = DefaultDecoder.new.decode(jwt_authorized)
    assert_equal "john.doe@example.com", identity.sub
    assert_equal "astral", identity.aud
  end

  # test "DecodeFactory.get finds correct decoder" do
  #   # no registered decoder returns default
  #   decoder = DecoderFactory.get({})
  #   assert decoder.instance_of?(DefaultDecoder)

  #   # no configured decoder returns default
  #   DecoderFactory.register(UnconfiguredDecoder.new)
  #   decoder = DecoderFactory.get({})
  #   assert decoder.instance_of?(DefaultDecoder)

  #   # no configured decoder returns itself
  #   DecoderFactory.register(ConfiguredDecoder.new)
  #   decoder = DecoderFactory.get({})
  #   assert decoder.instance_of?(ConfiguredDecoder)
  # end

  private
  class ConfiguredDecoder
    def configured(c)
      ConfiguredDecoder.new
    end
  end
  class UnconfiguredDecoder
    def configured(c)
      nil
    end
  end
end

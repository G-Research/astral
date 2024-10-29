require "test_helper"
require_relative '../../../app/lib/utils/decoder_factory'
require_relative '../../../app/lib/utils/jwks_decoder'

class DecoderTest < ActiveSupport::TestCase
  test "JwksDecoder returns correct identity" do
    token = File.read("test/fixtures/files/token.jwks")
    identity = JwksDecoder.new.decode(token)
    assert_equal "john.doe@example.com", identity.sub
    assert_equal "astral", identity.aud
  end

  test "DefaultDecoder returns correct identity" do
    identity = DefaultDecoder.new.decode(jwt_authorized)
    assert_equal "john.doe@example.com", identity.sub
    assert_equal "astral", identity.aud
  end
end

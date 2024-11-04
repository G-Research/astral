require "test_helper"

class SecretDecoderTest < ActiveSupport::TestCase
  test ".decode returns correct identity" do
    identity = Utils::SecretDecoder.new(Config[:jwt_signing_key]).
                 decode(jwt_authorized)
    assert_equal "john.doe@example.com", identity.sub
    assert_equal "astral", identity.aud
  end
end

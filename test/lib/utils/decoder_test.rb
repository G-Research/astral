require "test_helper"

class DecoderTest < ActiveSupport::TestCase
  setup do
  end

  test "xxxxxxxxxxxxx" do
    token = File.read("test/fixtures/files/token.jwks")
    identity = Services::Auth.authenticate!(token)
    assert_equal "john.doe@example.com", identity.sub
    assert_equal "astral", identity.aud
  end
end

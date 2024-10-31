require "test_helper"
require "jwt"
require "openssl"
require "json"
require "tempfile"
require_relative "../../../app/lib/utils/decoder_factory"
require_relative "../../../app/lib/utils/jwks_decoder"

class DecoderTest < ActiveSupport::TestCase
  test "jwksdecoder.decode returns correct identity" do
    jwk = generate_jwks_signing_key
    token = generate_jwks_token(jwk)
    keyset_path = generate_jwks_keyset(jwk)

    identity = JwksDecoder.new(keyset_path).decode(token)
    assert_equal "john.doe@example.com", identity.sub
    assert_equal "astral", identity.aud
  end

  test "secretdecoder.decode returns correct identity" do
    identity = SecretDecoder.new(Config[:jwt_signing_key]).
                 decode(jwt_authorized)
    assert_equal "john.doe@example.com", identity.sub
    assert_equal "astral", identity.aud
  end

  test "DecodeFactory.get returns configured decoder" do
    decoders = [ UnconfiguredDecoder.new, ConfiguredDecoder.new ]
    DecoderFactory.stub :decoders, decoders do
      decoder = DecoderFactory.get({})
      assert decoder.instance_of?(ConfiguredDecoder)
    end
  end

  test "DecodeFactory.get recognizes invalid config" do
    decoders = [ ConfiguredDecoder.new, ConfiguredDecoder.new ]
    DecoderFactory.stub :decoders, decoders do
      assert_raises(
        RuntimeError, "Exactly one decoder must be configured") do
        decoder = DecoderFactory.get({})
      end
    end
  end

  private

  def generate_jwks_signing_key
    optional_parameters = { kid: "1", use: "sig", alg: "RS256" }
    jwk = JWT::JWK.new(OpenSSL::PKey::RSA.new(2048), optional_parameters)
  end

  def generate_jwks_token(jwk)
    payload = { "sub"=>"john.doe@example.com", "name"=>"John Doe", "iat"=>1516239022,
               "groups"=>[ "group1", "group2" ], "aud"=>"astral" }

    JWT.encode(payload, jwk.signing_key, jwk[:alg], kid: jwk[:kid])
  end

  def generate_jwks_keyset(jwk)
    jwks_hash = JWT::JWK::Set.new(jwk).export
    f = Tempfile.new
    f.write(JSON.pretty_generate(jwks_hash))
    f.close
    f.path
  end

  class ConfiguredDecoder
    def configured?(c) = true
  end

  class UnconfiguredDecoder
    def configured?(c) = false
  end
end

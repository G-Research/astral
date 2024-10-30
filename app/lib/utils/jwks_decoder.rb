require "open-uri"
class JwksDecoder
  def initialize(url)
    @url = url
  end

  def configured?(config)
    !@url.nil?
  end

  # Decode a JWT token signed with JWKS
  def decode(token)
    jwks = get_jwks_keyset_from_configured_url
    jwks = filter_out_non_signing_keys(jwks)
    body = JWT.decode(token, nil, true,
                      algorithms: get_algorithms_from_keyset(jwks),
                      jwks: jwks)[0]
    Identity.new(body)
  rescue => e
    Rails.logger.warn "Unable to decode token: #{e}"
    nil
  end

  private

  def get_jwks_keyset_from_configured_url
    jwks_json = URI.open(@url) { |f| f.read }
    JWT::JWK::Set.new(JSON.parse(jwks_json))
  end

  def filter_out_non_signing_keys(jwks)
    jwks.filter { |k| k[:use] == "sig" }
  end

  def get_algorithms_from_keyset(jwks)
    jwks.map { |k| k[:alg] }.compact.uniq
  end
end

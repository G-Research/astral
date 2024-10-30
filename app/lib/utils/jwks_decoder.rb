require 'open-uri'
class JwksDecoder
  def configured(config)
    !@url.nil?
  end

  def initialize(url)
    @url = url
  end

  def decode(token)
    # Decode a JWT access token using the configured base.
    jwks_hash = URI.open(@url) { |f| f.read }
    jwks = JWT::JWK::Set.new(JSON.parse(jwks_hash))
    jwks.filter! {|key| key[:use] == 'sig' }
    algorithms = jwks.map { |key| key[:alg] }.compact.uniq
    body = JWT.decode(token, nil, true, algorithms: algorithms, jwks: jwks)[0]
    Identity.new(body)
  rescue => e
    Rails.logger.warn "Unable to decode token: #{e}"
    nil
  end
end
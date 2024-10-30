class DefaultDecoder
  def configured?(config)
    true
  end

  def decode(token)
    # Decode a JWT access token using the configured base.
    body = JWT.decode(token, Config[:jwt_signing_key])[0]
    Identity.new(body)
  rescue => e
    Rails.logger.warn "Unable to decode token: #{e}"
    nil
  end
end
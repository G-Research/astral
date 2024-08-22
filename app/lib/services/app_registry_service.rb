module Services
  class AppRegistryService
    def authenticate!(token)
      identity = decode(token)
      raise AuthError unless identity
      # TODO verify identity with authority?
      identity
    end

    def authorize!(identity, cert_req)
      cert_req.fqdns.each do |fqdn|
        domain = get_domain_name(fqdn)
        raise AuthError unless (domain[:auto_approved_groups] & identity[:groups]).any?
      end
    end

    private
    
    def decode(token)
      # Decode a JWT access token using the configured base.
      body = JWT.decode(token, Rails.application.config.astral[:jwt_signing_key])[0]
      HashWithIndifferentAccess.new body
    rescue => e
      Rails.logger.warn "Unable to decode token: #{e}"
      nil
    end
    
    def get_domain_name(fqdn)
      # TODO implement
    end
  end
end

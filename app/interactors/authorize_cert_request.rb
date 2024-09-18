class AuthorizeCertRequest
  include Interactor
  include FailOnError
  include AuditLogging


  def call
    context.request.fqdns.each do |fqdn|
      domain = Domain.where(fqdn: fqdn).first
      raise AuthError.new("Common or alt name not recognized") unless domain
      raise AuthError.new("No subject or group authorization") unless
        domain.users_array.include?(context.identity.subject) ||
        (domain.group_delegation? && (domain.groups_array & context.identity.groups).any?)
    end
    nil
  end
end

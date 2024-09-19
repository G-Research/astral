class AuthorizeCertRequest < ApplicationInteractor
  def call
    context.request.fqdns.each do |fqdn|
      domain = Domain.where(fqdn: fqdn).first
      context.fail!(error: AuthError.new("Common or alt name not recognized")) unless domain
      context.fail!(error: AuthError.new("No subject or group authorization")) unless
        domain.users_array.include?(context.identity.subject) ||
        (domain.group_delegation? && (domain.groups_array & context.identity.groups).any?)
    end
    nil
  ensure
    audit_log
  end
end

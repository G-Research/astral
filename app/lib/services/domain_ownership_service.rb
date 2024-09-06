module Services
  class DomainOwnershipService
    def authorize!(identity, cert_req)
      cert_req.fqdns.each do |fqdn|
        domain = Domain.where(fqdn: fqdn).first
        raise AuthError unless domain.present? &&
                               (domain.owner == identity.subject ||
                               (domain.group_delegation &&
                               (domain.groups & identity.groups).any?))
      end
      nil
    end
  end
end

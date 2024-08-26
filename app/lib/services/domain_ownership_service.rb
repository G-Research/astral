module Services
  class DomainOwnershipService
    def authorize!(identity, cert_req)
      cert_req.fqdns.each do |fqdn|
        domain = get_domain_name(fqdn)
        raise AuthError unless domain.owner == identity.subject ||
                                (domain.group_delegation &&
                                (domain.groups & identity.groups).any?)
      end
      nil
    end

    private

    def get_domain_name(fqdn)
      # TODO implement
    end
  end
end

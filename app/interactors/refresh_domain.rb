class RefreshDomain
  include Interactor

  def call
    domain_info = Services::DomainOwnershipService.new.get_domain_info(context.request.fqdn)
    domain_record = Domain.first_or_create(fqdn: context.request.fqdn)

    if !domain_info || domain_info["isDeleted"]
      domain_record.delete
      return
    end

    domain_record.update!(
      group_delegation: domain_info["ownerDelegatedRequestsToTeam"],
      groups: domain_info["autoApprovedGroups"],
      users: domain_info["autoApprovedServiceAccounts"]
    )
  rescue => e
    Rails.logger.warn("Continuing after error in #{self.class.name}: #{e.class.name}: #{e.message}")
  end
end

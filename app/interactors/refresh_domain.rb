class RefreshDomain < ApplicationInteractor
  def call
    domain_info = Services::DomainOwnership.get_domain_info(context.request.common_name)
    domain_record = Domain.find_or_create_by!(fqdn: context.request.common_name)
    if !domain_info
      domain_record.destroy!
      return
    end

    domain_record.update!(
      group_delegation: domain_info.group_delegation,
      groups: domain_info.groups,
      users: domain_info.users
    )
  rescue => e
    Rails.logger.warn("Continuing after error in #{self.class.name}: #{e.class.name}: #{e.message}")
  end
end

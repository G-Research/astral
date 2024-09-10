class AuthorizeRequest
  include Interactor
  include FailOnError

  def call
    context.request.fqdns.each do |fqdn|
      domain = Domain.where(fqdn: fqdn).first
      raise AuthError unless domain.present?
      raise AuthError unless (domain.users_array & [ context.identity.subject ]).any? ||
        (domain.group_delegation && (domain.groups_array & context.identity.groups).any?)
    end
    nil
  end
end

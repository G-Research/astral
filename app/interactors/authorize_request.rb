class AuthorizeRequest
  include Interactor

  def call
    Services::DomainOwnershipService.new.authorize!(context.identity, context.request)
  end
end

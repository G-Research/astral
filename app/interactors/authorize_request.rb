class AuthorizeRequest
  include Interactor

  def call
    Services::DomainOwnershipService.new.authorize!(context.identity, context.request)
  rescue AuthError => e
    context.error = e
    context.fail!
  end
end

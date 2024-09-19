class AuthenticateIdentity < ApplicationInteractor
  before do
    token = context.request.headers["Authorization"]
    context.token = token.split(" ").last if token
  end

  def call
    if identity = Services::AuthService.authenticate!(context.token)
      context.identity = identity
    else
      context.fail!(message: "Invalid token")
    end
  ensure
    audit_log
  end
end

class AuthenticateIdentity
  include Interactor

  before do
    token = context.request.headers["Authorization"]
    context.token = token.split(" ").last if token
  end

  def call
    if identity = Services::AuthService.new.authenticate!(context.token)
      context.identity = identity
    else
      context.fail!(message: "Invalid token")
    end
  rescue => e
    context.fail!(message: e.message)
  end
end

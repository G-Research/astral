class ReadSecret
  include Interactor
  include FailOnError
  include AuditLogging

  def call
    if secret = Services::SecretsService.kv_read(context.request.path)
      context.secret = secret
    else
      context.fail!(message: "Failed to read secret")
    end
  end
end

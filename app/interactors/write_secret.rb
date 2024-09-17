class WriteSecret
  include Interactor
  include FailOnError
  include AuditLogging

  def call
    if secret = Services::SecretsService.kv_write(context.request.path, context.request.data)
      context.secret = secret
    else
      context.fail!(message: "Failed to store secret")
    end
  end
end

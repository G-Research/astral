class DeleteSecret
  include Interactor
  include FailOnError
  include AuditLogging

  def call
    Services::SecretsService.kv_delete(context.request.path)
  end
end

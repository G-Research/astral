class DeleteSecret < ApplicationInteractor
  def call
    Services::SecretsService.kv_delete(context.request.path)
  ensure
    audit_log
  end
end

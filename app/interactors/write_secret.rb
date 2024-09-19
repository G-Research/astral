class WriteSecret < ApplicationInteractor
  def call
    if secret = Services::SecretsService.kv_write(context.request.path, context.request.data)
      context.secret = secret
    else
      context.fail!(message: "Failed to store secret")
    end
  ensure
    log
  end
end

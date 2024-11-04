class WriteSecret < ApplicationInteractor
  def call
    if secret = Services::KeyValue.write(context.identity, context.request.path, context.request.data)
      context.secret = secret
    else
      context.fail!(message: "Failed to store secret")
    end
  ensure
    audit_log
  end
end

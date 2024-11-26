class ReadSecret < ApplicationInteractor
  def call
    if secret = Services::KeyValue.read(context.identity, context.request.path)
      context.secret = secret
    else
      context.fail!(message: "Failed to read secret: #{context.request.path}")
    end
  ensure
    audit_log
  end
end

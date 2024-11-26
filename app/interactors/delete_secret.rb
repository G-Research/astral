class DeleteSecret < ApplicationInteractor
  def call
    Services::KeyValue.delete(context.identity, context.request.path)
  ensure
    audit_log
  end
end

class ApplicationInteractor
  include Interactor

  def audit_log
    return if context.identity.nil?
    result = context.success? ? "success" : "failure"
    payload = {
      request_id: Thread.current[:request_id],
      action: "#{self.class.name}",
      result: result,
      error: context.error&.message,
      subject: context.identity&.subject,
      cert_common_name: context.request&.try(:common_name),
      kv_path: context.request&.try(:kv_path)
    }.compact!
    AuditLog.create!(payload)
  end
end

class ApplicationInteractor
  include Interactor

  def audit_log
    result = context.success? ? "success" : "failure"
    level = context.success? ? :info : :error
    payload = {
      action: "#{self.class.name}",
      result: result,
      error: context.error&.message,
      subject: context.identity&.subject,
      cert_common_name: context.request&.try(:common_name),
      kv_path: context.request&.try(:kv_path)
    }.compact!
    AuditLogger.new.send(level, payload)
  end
end

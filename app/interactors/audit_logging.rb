module AuditLogging
  extend ActiveSupport::Concern

  included do
    around do |interactor|
      interactor.call
      log
    rescue => e
      log
      raise e
    end
  end

  private

  def log
    result = context.success? ? "success" : "failure"
    level = context.success? ? :info : :error
    payload = {
      action: "#{self.class.name}",
      result: result,
      error: context.error&.message,
      subject: context.identity&.subject,
      cert_common_name: context.request&.try(:common_name)
    }
    AuditLogger.new.send(level, payload)
  end
end

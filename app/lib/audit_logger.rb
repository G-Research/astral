class AuditLogger < ActiveSupport::Logger
  def initialize
    super(Rails.configuration.astral[:audit_log_file])
    self.formatter = AuditLogFormatter.new
  end
end

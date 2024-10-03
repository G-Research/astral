class AuditLogger < ActiveSupport::Logger
  def initialize
    super(Config[:audit_log_file])
    self.formatter = AuditLogFormatter.new
  end
end

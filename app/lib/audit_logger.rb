class AuditLogger < ActiveSupport::Logger
  def initialize
    super(Config[:audit_log_file])
    self.formatter = JsonLogFormatter.new
  end
end

Rails.application.config.to_prepare do
  Rails.logger = ActiveSupport::Logger.new(STDOUT)
  Rails.logger.formatter = JsonLogFormatter.new
end

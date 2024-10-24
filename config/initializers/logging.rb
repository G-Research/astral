Rails.logger = JsonTaggedLogger::Logger.new(Rails.logger)
Rails.configuration.log_tags = JsonTaggedLogger::LogTagsConfig.generate(
  :request_id
)

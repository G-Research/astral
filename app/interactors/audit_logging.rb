module AuditLogging
  extend ActiveSupport::Concern

  included do
    around do |interactor|
      logger = AuditLogger.new
      logger.info(message: "#{self.class.name} begin")
      interactor.call
      if context.failed?
        logger.error(message: "#{self.class.name} failed")
      else
        logger.info(message: "#{self.class.name} succeeded")
      end
    rescue => e
      logger.error(message: "#{self.class.name} failed")
      raise e
    end
  end
end

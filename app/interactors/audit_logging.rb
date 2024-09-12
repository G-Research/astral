module AuditLogging
  extend ActiveSupport::Concern

  included do
    around do |interactor|
      logger = AuditLogger.new
      logger.info("#{self.class.name} begin")
      interactor.call
      if context.failed?
        logger.error("#{self.class.name} failed")
      else
        logger.info("#{self.class.name} succeeded")
      end
    end
  end
end

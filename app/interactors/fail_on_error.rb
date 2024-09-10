module FailOnError
  extend ActiveSupport::Concern

  included do
    around do |interactor|
      interactor.call
    rescue => e
      Rails.logger.error("Error in #{self.class.name}: #{e.class.name} - #{e.message}")
      context.fail!(error: e)
    end
  end
end

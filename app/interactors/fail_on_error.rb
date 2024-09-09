module FailOnError
  extend ActiveSupport::Concern

  included do
    around do |interactor|
      interactor.call
    rescue => e
      context.fail!(error: e)
    end
  end
end

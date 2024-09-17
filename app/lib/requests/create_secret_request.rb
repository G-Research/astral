module Requests
  class CreateSecretRequest
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :path, :string
    attribute :data, Hash

    validates :path, presence: true
  end
end

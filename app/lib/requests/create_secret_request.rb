module Requests
  class CreateSecretRequest
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :path, :string
    attribute :data, :hash

    validates :path, presence: true
  end
end

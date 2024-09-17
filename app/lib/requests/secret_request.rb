module Requests
  class SecretRequest
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :path, :string
    attribute :data

    validates :path, presence: true
  end
end

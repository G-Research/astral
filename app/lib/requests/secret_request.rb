module Requests
  class SecretRequest
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :path, :string
    attribute :data
    alias_attribute :kv_path, :path

    validates :path, presence: true
  end
end

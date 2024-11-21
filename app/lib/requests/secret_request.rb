module Requests
  class SecretRequest
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :path, :string
    attribute :groups, :string
    attribute :data
    alias_attribute :kv_path, :path

    validates :path, presence: true

    def groups_array
      (groups || "").split(",").sort.uniq
    end
  end
end

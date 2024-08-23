class Identity
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :subject, :string
  attribute :groups, array: :string, default: []
end

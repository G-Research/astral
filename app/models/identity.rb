class Identity
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :subject, :string
  attribute :name, :string
  attribute :iat, :integer
  attribute :aud, :string
  attribute :groups, array: :string, default: []

  alias_attribute :sub, :subject
  alias_attribute :roles, :groups
end

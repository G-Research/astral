class DomainInfo
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :owner, :string
  attribute :groups, array: :string, default: []
  attribute :group_delegation, :boolean, default: false
end

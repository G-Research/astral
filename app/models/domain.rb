class Domain < ApplicationRecord
  validates :fqdn, presence: true

  serialize :groups, type: Array, coder: JSON
  serialize :users, type: Array, coder: JSON


  if Config[:db_encryption]
    encrypts :fqdn, :users, :groups
  end
end

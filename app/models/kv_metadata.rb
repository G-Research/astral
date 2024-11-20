class KvMetadata < ApplicationRecord
  validates :path, presence: true
  validates :owner, presence: true

  serialize :read_groups, type: Array, coder: JSON
  serialize :write_groups, type: Array, coder: JSON

  if Config[:db_encryption]
    encrypts :path, :owner, :read_groups, :write_groups
  end
end

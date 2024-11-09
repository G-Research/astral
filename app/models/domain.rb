class Domain < ApplicationRecord
  validates :fqdn, presence: true

  if Config[:db_encryption]
    encrypts :fqdn, :users, :groups
  end

  def groups_array
    (groups || "").split(",").sort.uniq
  end

  def users_array
    (users || "").split(",").sort.uniq
  end
end

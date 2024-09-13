class Domain < ApplicationRecord
  validates :fqdn, presence: true

  def groups_array
    (groups || "").split(",").sort.uniq
  end

  def users_array
    (users || "").split(",").sort.uniq
  end
end

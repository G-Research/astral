class Domain < ApplicationRecord
  serialize :groups, :users, coder: YAML, type: Array
  before_save :clean_users_groups

  validates :fqdn, presence: true

  def clean_users_groups
    self.groups = groups.sort.uniq
    self.users = users.sort.uniq
  end
end

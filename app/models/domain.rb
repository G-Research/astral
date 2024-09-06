class Domain < ApplicationRecord
  serialize :groups, coder: YAML, type: Array
  before_save :clean_groups

  validates :fqdn, :owner, presence: true

  def clean_groups
    self.groups = groups.sort.uniq
  end
end

class Domain < ApplicationRecord
  serialize :groups, coder: YAML, type: Array
  before_save :clean_groups

  def clean_groups
    self.groups = groups.sort.uniq
  end
end

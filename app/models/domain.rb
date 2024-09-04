class Domain < ApplicationRecord
  serialize :groups, coder: JSON, type: Array
  before_save :clean_groups

  def clean_groups
    this.groups = groups.sort.uniq
  end
end

class FeatureOverride < ApplicationRecord
  belongs_to :feature
  validates :target_type, presence: true, inclusion: { in: ["User", "Group"] }
  validates :target_identifier, presence: true
  validates :enabled, inclusion: { in: [true, false] }
end
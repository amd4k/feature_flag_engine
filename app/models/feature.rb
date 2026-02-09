class Feature < ApplicationRecord
  has_many :feature_overrides, dependent: :destroy
  validates :key, uniqueness: true, presence: true
end
# == Schema Information
#
# Table name: activity_types
#
#  active               :boolean          default(TRUE)
#  activity_category_id :integer
#  created_at           :datetime         not null
#  description          :text
#  id                   :integer          not null, primary key
#  name                 :string
#  updated_at           :datetime         not null
#
# Indexes
#
#  index_activity_types_on_active                (active)
#  index_activity_types_on_activity_category_id  (activity_category_id)
#
# Foreign Keys
#
#  fk_rails_60d4f5f88d  (activity_category_id => activity_categories.id)
#

class ActivityType < ApplicationRecord
  belongs_to :activity_category
  scope :active, -> { where(active: true) }
  validates_presence_of :name, :activity_category_id
end

# == Schema Information
#
# Table name: meter_attributes
#
#  attribute_type :string           not null
#  created_at     :datetime         not null
#  created_by_id  :bigint(8)
#  deleted_by_id  :bigint(8)
#  id             :bigint(8)        not null, primary key
#  input_data     :json
#  meter_id       :bigint(8)        not null
#  reason         :text
#  replaced_by_id :bigint(8)
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_meter_attributes_on_meter_id  (meter_id)
#
# Foreign Keys
#
#  fk_rails_...  (created_by_id => users.id) ON DELETE => nullify
#  fk_rails_...  (deleted_by_id => users.id) ON DELETE => nullify
#  fk_rails_...  (meter_id => meters.id) ON DELETE => cascade
#  fk_rails_...  (replaced_by_id => meter_attributes.id) ON DELETE => nullify
#

class MeterAttribute < ApplicationRecord
  belongs_to :meter
  belongs_to :replaced_by, class_name: 'MeterAttribute', optional: true
  belongs_to :deleted_by, class_name: 'User', optional: true
  belongs_to :created_by, class_name: 'User', optional: true
  has_one :replaces, class_name: 'MeterAttribute', foreign_key: :replaced_by_id

  scope :active,  -> { where(replaced_by_id: nil, deleted_by_id: nil) }
  scope :deleted, -> { where(replaced_by_id: nil).where.not(deleted_by_id: nil) }

  def to_analytics
    meter_attribute_type.parse(input_data).to_analytics
  end

  def meter_attribute_type
    MeterAttributes.all[attribute_type.to_sym]
  end

  def self.to_analytics(meter_attributes)
    meter_attributes.inject({}) do |collection, attribute|
      aggregation = attribute.meter_attribute_type.attribute_aggregation
      if aggregation
        collection[aggregation] ||= []
        collection[aggregation] << attribute.to_analytics
        collection
      else
        collection.merge(attribute.to_analytics)
      end
    end
  end
end

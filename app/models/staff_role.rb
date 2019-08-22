# == Schema Information
#
# Table name: staff_roles
#
#  created_at :datetime         not null
#  id         :bigint(8)        not null, primary key
#  title      :string           not null
#  updated_at :datetime         not null
#

class StaffRole < ApplicationRecord
  has_many :users
end

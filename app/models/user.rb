# == Schema Information
#
# Table name: users
#
#  id         :bigint(8)        not null, primary key
#  uuid       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class User < ApplicationRecord
  has_many :accounts, dependent: :destroy
end

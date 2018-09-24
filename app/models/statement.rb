# == Schema Information
#
# Table name: statements
#
#  id                       :bigint(8)        not null, primary key
#  account_id               :bigint(8)
#  starting_at              :datetime         not null
#  ending_at                :datetime         not null
#  starting_amount_cents    :integer
#  starting_amount_currency :string
#  ending_amount_cents      :integer          not null
#  ending_amount_currency   :string           not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#

class Statement < ApplicationRecord
  belongs_to :account
end

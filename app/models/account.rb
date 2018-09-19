# == Schema Information
#
# Table name: accounts
#
#  id              :bigint(8)        not null, primary key
#  owner_id        :bigint(8)
#  currency        :string(3)        not null
#  account_type    :string           not null
#  account_subtype :string           not null
#  nickname        :string(70)
#  scheme_name     :string           not null
#  identification  :string(34)       not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

class Account < ApplicationRecord
  belongs_to :owner, class_name: 'User'
  has_many :transactions, dependent: :delete_all

  scope :for_user, ->(user) {
    where(owner: user).where.not(owner_id: nil)
  }
end

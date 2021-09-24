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
#  state           :integer          default(1)
#  closed_at       :datetime
#

class PrivateAccountSerializer
  include FastJsonapi::ObjectSerializer

  attributes :account_type, :account_subtype, :identification

  attributes :owner_uuid do |account|
    account.owner.uuid
  end
end

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

class AccountSerializer
  include OpenBankingObjectSerializer

  attributes :currency, :account_type

  attribute :account_id, &:id
  attribute :account_sub_type, &:account_subtype # renamed to fix camel casing
  attribute :nickname, if: ->(account, params) { account.nickname.present? }

  # per spec, the following should only be returned if authorized consent has permission for ReadAccountsDetail
  attribute :account do |account|
    {SchemeName: account.scheme_name, Identification: account.identification}
  end
end

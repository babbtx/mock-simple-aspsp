# == Schema Information
#
# Table name: transactions
#
#  id               :bigint(8)        not null, primary key
#  account_id       :bigint(8)
#  amount_cents     :integer          default(0), not null
#  amount_currency  :string           not null
#  booked_at        :datetime         not null
#  credit_or_debit  :integer          not null
#  description      :string
#  balance_cents    :integer          default(0), not null
#  balance_currency :string           not null
#  merchant_name    :string
#  merchant_code    :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

class TransactionSerializer
  include OpenBankingObjectSerializer

  attributes :account_id

  attribute :transaction_id, &:id

  attribute :status do |tx|
    'Booked'
  end

  attribute :credit_debit_indicator do |tx|
    tx.credit? ? 'Credit' : 'Debit'
  end

  attribute :booking_date_time do |tx|
    tx.booked_at.localtime.iso8601
  end

  attribute :amount do |tx|
    {Amount: tx.amount.format(symbol: false), Currency: tx.amount.currency.iso_code}
  end

  # per spec, the following should only be returned if authorized consent has permission for ReadTransactionsDetail
  attribute :transaction_information, &:description

  # per spec, the following should only be returned if authorized consent has permission for ReadTransactionsDetail
  attribute :balance do |tx|
    {
      Amount: { Amount: tx.balance.format(symbol: false), Currency: tx.balance.currency.iso_code },
      CreditDebitIndicator: 'Credit',
      Type: 'InterimBooked'
    }
  end

  # per spec, the following should only be returned if authorized consent has permission for ReadTransactionsDetail
  attribute :merchant_details, if: ->(tx, params) {
    tx.merchant_name.present? || tx.merchant_code.present?
  } do |tx|
    {MerchantName: tx.merchant_name, MerchantCategoryCode: tx.merchant_code}
  end
end

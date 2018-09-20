class BalanceSerializer
  include OpenBankingObjectSerializer

  attributes :account_id

  attribute :amount do |tx|
    { Amount: tx.balance.format(symbol: false), Currency: tx.balance.currency.iso_code }
  end

  attribute :credit_debit_indicator do |tx|
    'Credit'
  end

  attribute :type do |tx|
    'InterimBooked'
  end

  attribute :date_time do |tx|
    tx.booked_at.localtime.iso8601
  end
end

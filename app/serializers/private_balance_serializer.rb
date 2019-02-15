class PrivateBalanceSerializer
  include FastJsonapi::ObjectSerializer

  attributes :account_id

  attribute :amount do |tx|
    tx.balance.format(symbol: false, thousands_separator: false).to_f
  end

  attribute :currency do |tx|
    tx.balance.currency.iso_code
  end

  attribute :date_time do |tx|
    tx.booked_at.localtime.iso8601
  end
end

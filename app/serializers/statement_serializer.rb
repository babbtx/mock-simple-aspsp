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

class StatementSerializer
  include OpenBankingObjectSerializer

  attributes :account_id
  attribute :statement_id, &:id

  attribute :type do |stmt|
    'RegularPeriodic'
  end

  attribute :start_date_time do |stmt|
    stmt.starting_at.localtime.iso8601
  end

  attribute :end_date_time do |stmt|
    stmt.ending_at.localtime.iso8601
  end

  attribute :creation_date_time do |stmt|
    stmt.created_at.localtime.iso8601
  end

  attribute :statement_amount do |stmt|
    [
        {
            Amount: {Amount: stmt.starting_amount.format(symbol: false), Currency: stmt.starting_amount.currency.iso_code },
            CreditOrDebitIndicator: 'Credit',
            Type: 'StartingBalance'
        },
        {
            Amount: {Amount: stmt.ending_amount.format(symbol: false), Currency: stmt.ending_amount.currency.iso_code },
            CreditOrDebitIndicator: 'Credit',
            Type: 'ClosingBalance'
        }
    ]
  end

end

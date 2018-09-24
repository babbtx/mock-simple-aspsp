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

  monetize :starting_amount_cents
  monetize :ending_amount_cents

  scope :for_transaction_date, ->(datetime) {
    where('starting_at <= ? and ending_at > ?', datetime, datetime).limit(1)
  }

  before_validation :set_amounts_based_on_transactions

  def transactions
    Transaction.for_account(account_id)
      .where('booked_at >= ? and booked_at < ?', starting_at, ending_at)
      .oldest_first
  end

  private

  def set_amounts_based_on_transactions
    transactions = self.transactions.all
    unless transactions.empty?
      balance_adjustment = transactions.first.amount
      balance_adjustment *= -1 if transactions.first.credit?
      self.starting_amount = transactions.first.balance + balance_adjustment
      self.ending_amount = transactions.last.balance
    end
  end

end

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
  has_one :account_owner, through: :account, source: :owner

  monetize :starting_amount_cents
  monetize :ending_amount_cents

  scope :for_user, ->(user) {
    # joins(:account_owner).where(account_owner: {id: user.id}) # This doesn't work
    joins(:account).where(accounts: {owner_id: user.id})
  }
  scope :for_account, ->(account) {
    account_id = Account === account ? account.id : account
    where(account_id: account_id)
  }
  scope :for_transaction_date, ->(datetime) {
    where('starting_at <= ? and ending_at > ?', datetime, datetime).limit(1)
  }
  scope :oldest_first, -> {
    order(created_at: :asc)
  }

  before_validation :set_amounts_based_on_transactions

  def transactions
    Transaction.for_account(account_id)
      .where('booked_at >= ? and booked_at < ?', starting_at, ending_at)
      .oldest_first
  end

  def to_csv
    # nothing about the statement itself; just return the transactions
    transactions.oldest_first.to_csv
  end

  private

  def set_amounts_based_on_transactions
    transactions = self.transactions.all
    unless transactions.empty?
      self.starting_amount = transactions.first.balance
      self.ending_amount = transactions.last.balance
    end
  end

end

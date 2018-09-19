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

class Transaction < ApplicationRecord
  belongs_to :account
  has_one :account_owner, through: :account, source: :owner

  CREDIT = 0.freeze
  DEBIT = 1.freeze
  enum credit_or_debit: { credit: CREDIT, debit: DEBIT }

  monetize :amount_cents
  monetize :balance_cents

  scope :for_user, ->(user) {
    # joins(:account_owner).where(account_owner: {id: user.id}) # This doesn't work
    joins(:account).where(accounts: {owner_id: user.id})
  }
  scope :for_account, ->(account) {
    account_id = Account === account ? account.id : account
    where(account_id: account_id)
  }
  scope :before, ->(record) {
    where('account_id = ? and booked_at <= ?', record.account_id, record.booked_at)
        .where.not(id: record.id)
        .order({booked_at: :desc}, {id: :desc})
  }
  scope :after, ->(record) {
    where('account_id = ? and booked_at >= ?', record.account_id, record.booked_at)
        .where.not(id: record.id)
        .order(:booked_at, :id)
  }

  before_validation :set_balance_based_on_transaction_before
  after_save :update_balances_after

  private

  def set_balance_based_on_transaction_before
    adjusted_amount = self.amount
    adjusted_amount *= -1 if self.debit?
    before = Transaction.before(self).first
    self.balance = before.nil? ? adjusted_amount : before.balance + adjusted_amount
  end

  def update_balances_after
    # grab the next transaction after this one and save it
    # that recalculates the balance based on this one and continues the process
    # of course, this row locks everything for this account, so this is not very "real world"
    after = Transaction.after(self).first
    after.save if after
  end
end

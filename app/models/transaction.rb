# == Schema Information
#
# Table name: transactions
#
#  id               :bigint(8)        not null, primary key
#  account_id       :bigint(8)
#  amount_cents     :integer          not null
#  amount_currency  :string           not null
#  booked_at        :datetime         not null
#  credit_or_debit  :integer          not null
#  description      :string
#  balance_cents    :integer          not null
#  balance_currency :string           not null
#  merchant_name    :string
#  merchant_code    :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
require 'csv'

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
  scope :before, ->(datetime) {
    where('booked_at <= ?', datetime)
  }
  scope :before_transaction, ->(record) {
    where('account_id = ? and booked_at < ?', record.account_id, record.booked_at)
        .where.not(id: record.id)
        .order({booked_at: :desc}, {id: :desc})
  }
  scope :after, ->(datetime) {
    where('booked_at >= ?', datetime)
  }
  scope :after_transaction, ->(record) {
    where('account_id = ? and booked_at >= ?', record.account_id, record.booked_at)
        .where.not(id: record.id)
        .order(:booked_at, :id)
  }
  scope :newest_first, ->() {
    order(booked_at: :desc)
  }
  scope :oldest_first, ->() {
    order(booked_at: :asc)
  }

  attr_accessor :during_generation
  before_validation :set_balance_based_on_transaction_before, unless: :during_generation
  after_save :update_balances_on_transactions_after, unless: :during_generation
  after_save :update_statement_containing_transaction, unless: :during_generation

  def self.to_csv
    attrs_map = {
        id: 'Transaction Id',
        booked_at: 'Date Time',
        description: 'Description',
        merchant_name: 'Merchant',
        merchant_code: 'Merchant Code',
        amount: 'Amount',
        balance: 'Balance'
    }
    CSV.generate(headers: true) do |csv|
      csv << attrs_map.values
      all.each do |tx|
        csv << attrs_map.collect do |(attr,label)|
          case attr
            when :booked_at
              tx.booked_at.localtime.iso8601
            when :amount
              amount = tx.amount
              amount *= -1 if tx.debit?
              amount.format(disambiguate: true)
            when :balance
              tx.balance.format(disambiguate: true)
            else
              tx.public_send(attr)
          end
        end
      end
    end
  end

  private

  def set_balance_based_on_transaction_before
    adjusted_amount = self.amount
    adjusted_amount *= -1 if self.debit?
    before = Transaction.before_transaction(self).first
    self.balance = before.nil? ? adjusted_amount : before.balance + adjusted_amount
  end

  def update_balances_on_transactions_after
    # grab the next transaction after this one and save it
    # that recalculates the balance based on this one and continues the process
    # of course, this row locks everything for this account, so this is not very "real world"
    after = Transaction.after_transaction(self).first
    after.save if after
  end

  def update_statement_containing_transaction
    # the statement calculates its amounts based on the transactions
    # grab the statement that should contain this transaction and re-save it
    statement = Statement.for_transaction_date(booked_at).first
    statement.save if statement
  end
end

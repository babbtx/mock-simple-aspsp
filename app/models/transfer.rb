class Transfer
  include ActiveModel::Model
  define_model_callbacks :save

  attr_accessor :from_account_id, :to_account_id
  attr_accessor :amount_cents, :amount_currency
  attr_accessor :amount

  # validates that the account exists and also sets @from_account or @to_account
  class AccountValidator < ActiveModel::EachValidator
    def validate_each(record, attribute, value)
      return if value.blank?
      account_ivar = '@' + attribute.to_s.sub(/_id$/, '')
      account_record = Account.find_by(id: value)
      if account_record
        record.instance_variable_set(account_ivar, account_record)
      else
        record.errors.add(attribute, "not found")
      end
    end
  end

  validates :from_account_id, presence: true, account: true
  validates :to_account_id, presence: true, account: true
  validate :accounts_have_same_currency
  validates :amount, numericality: {greater_than: 0}

  def save
    return false unless valid?

    Transaction.transaction do
      now = DateTime.now
      Transaction.create! account: @from_account,
                          amount: Monetize.parse!(self.amount, @from_account.currency),
                          credit_or_debit: Transaction::DEBIT,
                          booked_at: now
      Transaction.create! account: @to_account,
                          amount: Monetize.parse!(self.amount, @from_account.currency),
                          credit_or_debit: Transaction::CREDIT,
                          booked_at: now
    end
  end

  def self.create(params)
    transfer = self.new(params)
    transfer.save
    transfer
  end

  private

  def accounts_have_same_currency
    if @from_account && @to_account
      if @from_account.currency != @to_account.currency
        self.errors.add(:base, :not_same_currency, message: 'accounts must have the same currency')
      end
    end
  end
end
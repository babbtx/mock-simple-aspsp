class CreateTransactions < ActiveRecord::Migration[5.2]
  def change
    create_table :transactions do |t|
      t.belongs_to :account, foreign_key: true
      t.monetize :amount, null: false, currency: {null: false, default: nil}
      t.datetime :booked_at, null: false
      t.integer :credit_or_debit, null: false
      t.string :description
      t.monetize :balance, null: false, currency: {null: false, default: nil}
      t.string :merchant_name
      t.string :merchant_code

      t.timestamps
    end
  end
end

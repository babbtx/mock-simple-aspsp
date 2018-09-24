class CreateStatements < ActiveRecord::Migration[5.2]
  def change
    create_table :statements do |t|
      t.belongs_to :account, foreign_key: true
      t.datetime :starting_at, null: false
      t.datetime :ending_at, null: false
      t.monetize :starting_amount, amount: {null: true, default: nil}, currency: {null: true, default: nil}
      t.monetize :ending_amount, amount: {null: false, default: nil}, currency: {null: false, default: nil}

      t.timestamps
    end
  end
end

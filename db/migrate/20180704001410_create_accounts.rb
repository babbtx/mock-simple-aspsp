class CreateAccounts < ActiveRecord::Migration[5.2]
  def change
    create_table :accounts do |t|
      t.belongs_to :owner, foreign_key: {to_table: :users}
      t.string :currency, limit: 3, null: false
      t.string :account_type, null: false
      t.string :account_subtype, null: false
      t.string :nickname, limit: 70

      # OBReadAccount2/Data/Account/Account
      t.string :scheme_name, null: false
      t.string :identification, limit: 34, null: false

      t.timestamps
    end
  end
end

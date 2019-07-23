class AddStateToAccount < ActiveRecord::Migration[5.2]
  def change
    add_column :accounts, :state, :integer, default: 1
    add_column :accounts, :closed_at, :datetime
  end
end

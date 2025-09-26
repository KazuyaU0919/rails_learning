class AddAdminFlagsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :editor, :boolean, default: false, null: false
    add_column :users, :banned_at, :datetime
    add_column :users, :ban_reason, :string
  end
end

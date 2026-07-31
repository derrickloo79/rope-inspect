class AddContactToUsers < ActiveRecord::Migration[7.2]
  def up
    add_column :users, :country_code, :string, null: false, default: "+65"
    add_column :users, :contact_number, :string

    # Placeholder so existing staff rows pass NOT NULL; admins should update to real numbers.
    execute <<~SQL.squish
      UPDATE users
      SET contact_number = '00000000'
      WHERE contact_number IS NULL OR contact_number = ''
    SQL

    change_column_null :users, :contact_number, false
  end

  def down
    remove_column :users, :contact_number
    remove_column :users, :country_code
  end
end

class AddNameToUsers < ActiveRecord::Migration[7.2]
  def up
    add_column :users, :name, :string
    # Backfill existing staff so validation passes after deploy.
    execute <<~SQL.squish
      UPDATE users
      SET name = split_part(email, '@', 1)
      WHERE name IS NULL OR name = ''
    SQL
    change_column_null :users, :name, false
  end

  def down
    remove_column :users, :name
  end
end

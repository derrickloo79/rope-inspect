class CreateFsps < ActiveRecord::Migration[7.2]
  def change
    create_table :fsps do |t|
      t.string :full_name, null: false
      t.string :contact_number, null: false
      t.string :email, null: false
      t.integer :sequence_number, null: false
      t.string :fsp_number, null: false
      t.date :date_joined, null: false
      t.string :color, null: false

      t.timestamps
    end

    add_index :fsps, :sequence_number, unique: true
    add_index :fsps, :fsp_number, unique: true
    add_index :fsps, :color, unique: true
    add_index :fsps, :email
  end
end

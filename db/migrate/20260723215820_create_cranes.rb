class CreateCranes < ActiveRecord::Migration[7.2]
  def change
    create_table :cranes do |t|
      t.references :inspection_request, null: false, foreign_key: true
      t.string :crane_type, null: false
      t.string :lm_number, null: false
      t.decimal :rope_diameter_mm, precision: 5, scale: 2, null: false
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :cranes, [ :inspection_request_id, :position ]
  end
end

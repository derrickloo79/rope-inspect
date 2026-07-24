class ChangeRopeDiameterToTextOnCranes < ActiveRecord::Migration[7.2]
  def up
    change_column :cranes, :rope_diameter_mm, :string, null: false
  end

  def down
    change_column :cranes, :rope_diameter_mm, :decimal, precision: 5, scale: 2, null: false
  end
end

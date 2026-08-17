class AddCraneTypeOtherToCranes < ActiveRecord::Migration[7.2]
  def change
    add_column :cranes, :crane_type_other, :string
  end
end

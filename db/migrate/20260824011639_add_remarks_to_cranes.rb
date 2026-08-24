class AddRemarksToCranes < ActiveRecord::Migration[7.2]
  def change
    add_column :cranes, :remarks, :text
  end
end

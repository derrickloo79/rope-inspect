class AddCountryCodeToFsps < ActiveRecord::Migration[7.2]
  def change
    add_column :fsps, :country_code, :string, null: false, default: "+65"
  end
end

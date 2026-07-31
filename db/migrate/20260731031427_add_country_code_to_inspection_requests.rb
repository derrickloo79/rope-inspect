class AddCountryCodeToInspectionRequests < ActiveRecord::Migration[7.2]
  def change
    add_column :inspection_requests, :country_code, :string, null: false, default: "+65"
  end
end

class AddPointOfContactToInspectionRequests < ActiveRecord::Migration[7.2]
  def change
    add_column :inspection_requests, :poc_name, :string
    add_column :inspection_requests, :poc_country_code, :string, default: "+65"
    add_column :inspection_requests, :poc_contact_number, :string
  end
end

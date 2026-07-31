class AddSiteAccessToInspectionRequests < ActiveRecord::Migration[7.2]
  def change
    add_column :inspection_requests, :map_url, :string
    add_column :inspection_requests, :site_note, :text
  end
end

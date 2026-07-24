class AddRejectedAtToInspectionRequests < ActiveRecord::Migration[7.2]
  def change
    add_column :inspection_requests, :rejected_at, :datetime
  end
end

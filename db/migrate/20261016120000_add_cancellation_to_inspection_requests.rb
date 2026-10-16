class AddCancellationToInspectionRequests < ActiveRecord::Migration[7.2]
  def change
    add_column :inspection_requests, :cancellation_reason, :text
    add_column :inspection_requests, :cancelled_at, :datetime
  end
end

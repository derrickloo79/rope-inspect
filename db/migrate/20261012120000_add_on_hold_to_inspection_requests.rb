class AddOnHoldToInspectionRequests < ActiveRecord::Migration[7.2]
  def change
    add_column :inspection_requests, :on_hold_reason, :text
    add_column :inspection_requests, :on_hold_at, :datetime
  end
end

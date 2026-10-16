class AddAbortToInspectionRequests < ActiveRecord::Migration[7.2]
  def change
    add_column :inspection_requests, :abort_reason, :text
    add_column :inspection_requests, :aborted_at, :datetime
  end
end

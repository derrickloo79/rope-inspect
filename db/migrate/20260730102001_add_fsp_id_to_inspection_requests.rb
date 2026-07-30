class AddFspIdToInspectionRequests < ActiveRecord::Migration[7.2]
  def change
    add_reference :inspection_requests, :fsp, null: true, foreign_key: true
  end
end

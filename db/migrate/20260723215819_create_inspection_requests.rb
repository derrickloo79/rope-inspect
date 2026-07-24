class CreateInspectionRequests < ActiveRecord::Migration[7.2]
  def change
    create_table :inspection_requests do |t|
      t.string :company_name, null: false
      t.string :requestor_name, null: false
      t.string :contact_number, null: false
      t.string :email
      t.string :site_name, null: false
      t.string :status, null: false, default: "pending"
      t.string :share_token
      t.date :scheduled_on
      t.time :scheduled_time
      t.string :assigned_inspector
      t.text :notes
      t.datetime :accepted_at
      t.datetime :scheduled_at
      t.datetime :completed_at

      t.timestamps
    end

    add_index :inspection_requests, :status
    add_index :inspection_requests, :share_token, unique: true
  end
end

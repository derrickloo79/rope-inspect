class CreateJobEvents < ActiveRecord::Migration[7.2]
  def up
    create_table :job_events do |t|
      t.references :inspection_request, null: false, foreign_key: true
      t.references :user, foreign_key: { on_delete: :nullify }
      t.string :action, null: false
      t.jsonb :details, null: false, default: {}
      t.datetime :occurred_at, null: false
      t.timestamps
    end
    add_index :job_events, [ :inspection_request_id, :occurred_at ]

    # Existing jobs only have the latest timestamp for each step, so this
    # rebuilds that much of the log. Later actions record the admin as they happen.
    execute <<~SQL
      INSERT INTO job_events (inspection_request_id, action, details, occurred_at, created_at, updated_at)
      SELECT id, 'accepted', '{}'::jsonb, accepted_at, NOW(), NOW()
      FROM inspection_requests
      WHERE accepted_at IS NOT NULL
    SQL

    execute <<~SQL
      INSERT INTO job_events (inspection_request_id, action, details, occurred_at, created_at, updated_at)
      SELECT id, 'rejected', '{}'::jsonb, rejected_at, NOW(), NOW()
      FROM inspection_requests
      WHERE rejected_at IS NOT NULL
    SQL

    execute <<~SQL
      INSERT INTO job_events (inspection_request_id, action, details, occurred_at, created_at, updated_at)
      SELECT ir.id,
             'scheduled',
             jsonb_strip_nulls(jsonb_build_object(
               'scheduled_on', to_char(ir.scheduled_on, 'YYYY-MM-DD'),
               'period', CASE
                 WHEN ir.scheduled_time IS NULL THEN NULL
                 WHEN EXTRACT(HOUR FROM ir.scheduled_time) < 12 THEN 'AM'
                 ELSE 'PM'
               END,
               'fsp_number', fsps.fsp_number
             )),
             ir.scheduled_at,
             NOW(),
             NOW()
      FROM inspection_requests ir
      LEFT JOIN fsps ON fsps.id = ir.fsp_id
      WHERE ir.scheduled_at IS NOT NULL
    SQL

    execute <<~SQL
      INSERT INTO job_events (inspection_request_id, action, details, occurred_at, created_at, updated_at)
      SELECT id, 'on_hold', jsonb_build_object('reason', on_hold_reason), on_hold_at, NOW(), NOW()
      FROM inspection_requests
      WHERE on_hold_at IS NOT NULL
    SQL

    execute <<~SQL
      INSERT INTO job_events (inspection_request_id, action, details, occurred_at, created_at, updated_at)
      SELECT id, 'completed', '{}'::jsonb, completed_at, NOW(), NOW()
      FROM inspection_requests
      WHERE completed_at IS NOT NULL
    SQL

    execute <<~SQL
      INSERT INTO job_events (inspection_request_id, action, details, occurred_at, created_at, updated_at)
      SELECT id, 'aborted', jsonb_build_object('reason', abort_reason), aborted_at, NOW(), NOW()
      FROM inspection_requests
      WHERE aborted_at IS NOT NULL
    SQL

    execute <<~SQL
      INSERT INTO job_events (inspection_request_id, action, details, occurred_at, created_at, updated_at)
      SELECT id, 'cancelled', jsonb_build_object('reason', cancellation_reason), cancelled_at, NOW(), NOW()
      FROM inspection_requests
      WHERE cancelled_at IS NOT NULL
    SQL
  end

  def down
    drop_table :job_events
  end
end

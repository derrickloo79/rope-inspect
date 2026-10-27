class RelabelOnHoldReturnsAsScheduled < ActiveRecord::Migration[7.2]
  def up
    events = JobEvent.order(:inspection_request_id, :occurred_at, :id).group_by(&:inspection_request_id)
    events.each_value do |rows|
      from_hold = false
      rows.each do |event|
        case event.action
        when "on_hold"
          from_hold = true
        when "rescheduled"
          if from_hold
            event.update!(action: "scheduled")
            from_hold = false
          end
        when "scheduled"
          from_hold = false
        end
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end

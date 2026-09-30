class EnforceEventIdentifierUniqueness < ActiveRecord::Migration[7.1]
  def up
    change_column_null :event_stats, :event_id, false
    remove_index :events, name: "index_events_on_external_id"
    add_index :events, :external_id, unique: true
  end

  def down
    remove_index :events, :external_id
    add_index :events, :external_id
    change_column_null :event_stats, :event_id, true
  end
end

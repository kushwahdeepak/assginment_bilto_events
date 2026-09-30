class HardenEventStats < ActiveRecord::Migration[7.1]
  def up
    execute "UPDATE event_stats SET upvotes_count = 0 WHERE upvotes_count IS NULL"
    execute "UPDATE event_stats SET downvotes_count = 0 WHERE downvotes_count IS NULL"

    change_column_default :event_stats, :upvotes_count, 0
    change_column_default :event_stats, :downvotes_count, 0
    change_column_null :event_stats, :upvotes_count, false
    change_column_null :event_stats, :downvotes_count, false

    remove_index :event_stats, name: "index_event_stats_on_event_id"
    add_index :event_stats, :event_id, unique: true
  end

  def down
    remove_index :event_stats, :event_id
    add_index :event_stats, :event_id
    change_column_null :event_stats, :upvotes_count, true
    change_column_null :event_stats, :downvotes_count, true
    change_column_default :event_stats, :upvotes_count, nil
    change_column_default :event_stats, :downvotes_count, nil
  end
end
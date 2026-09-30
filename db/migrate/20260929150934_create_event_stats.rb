class CreateEventStats < ActiveRecord::Migration[7.1]
  def change
    create_table :event_stats do |t|
      t.string :event_id
      t.integer :upvotes_count
      t.integer :downvotes_count

      t.timestamps
    end
    add_index :event_stats, :event_id
  end
end

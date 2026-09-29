class CreateEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :events do |t|
      t.string :external_id
      t.string :title
      t.text :description
      t.datetime :start_date
      t.string :image_url

      t.timestamps
    end
    add_index :events, :external_id, unique: true
  end
end

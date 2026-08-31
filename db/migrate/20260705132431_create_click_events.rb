class CreateClickEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :click_events do |t|
      t.references :link, null: false, foreign_key: true
      t.timestamps
      t.index [:link_id, :created_at]
    end
  end
end

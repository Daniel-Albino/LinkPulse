class AddClickEventCountToLink < ActiveRecord::Migration[8.1]
  def change
    add_column :links, :click_events_count, :integer, default: 0, null: false
  end
end

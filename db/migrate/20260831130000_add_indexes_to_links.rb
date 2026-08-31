class AddIndexesToLinks < ActiveRecord::Migration[8.1]

  def up
    change_column_null :links, :short_code, true
    add_index :links, :short_code, unique: true, if_not_exists: true
    add_index :links, :url, unique: true, if_not_exists: true
    backfill_click_events_counts
  end

  def down
    remove_index :links, :url, if_exists: true
    remove_index :links, :short_code, if_exists: true
  end

  private

  def backfill_click_events_counts
    execute(<<~SQL)
      UPDATE links
      SET click_events_count = (
        SELECT COUNT(*) FROM click_events WHERE click_events.link_id = links.id
      )
    SQL
  end
end

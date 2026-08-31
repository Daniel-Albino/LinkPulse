class CreateLinks < ActiveRecord::Migration[8.1]
  def change
    create_table :links do |t|
      t.string :url, null: false
      t.string :short_code
      t.timestamps
    end
  end
end

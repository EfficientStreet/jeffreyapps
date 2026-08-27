class CreateBookmarks < ActiveRecord::Migration[8.0]
  def change
    create_table :bookmarks do |t|
      t.references :user, null: false, foreign_key: true
      t.string :url, null: false
      t.string :title, null: false
      t.string :url_type, null: false, default: "website"
      t.text :summary
      t.text :notes
      t.string :summary_status, null: false, default: "pending"

      t.timestamps
    end
    add_index :bookmarks, [ :user_id, :created_at ]
  end
end

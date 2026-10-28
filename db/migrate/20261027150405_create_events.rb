class CreateEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :events do |t|
      t.string :external_id
      t.string :title
      t.text :description
      t.string :image_url
      t.datetime :starts_at

      t.timestamps
    end
  end
end

class CreateEventVoteCounts < ActiveRecord::Migration[8.1]
  def change
    create_table :event_vote_counts do |t|
      t.references :event, null: false, foreign_key: true, index: { unique: true }
      t.integer :upvotes_count, default: 0, null: false
      t.integer :downvotes_count, default: 0, null: false

      t.timestamps
    end
  end
end

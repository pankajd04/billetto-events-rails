class AddBillettoFieldsToEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :events, :event_url, :string
    add_column :events, :ends_at, :datetime
    add_column :events, :state, :string
  end
end

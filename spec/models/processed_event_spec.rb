require 'rails_helper'

RSpec.describe ProcessedEvent, type: :model do
  describe "validations" do
    it "is valid with an event ID" do
      processed_event = ProcessedEvent.new(event_id: SecureRandom.uuid)

      expect(processed_event).to be_valid
    end

    it "requires an event ID" do
      processed_event = ProcessedEvent.new(event_id: nil)

      expect(processed_event).not_to be_valid
    end

    it "does not allow duplicate event IDs" do
      event_id = SecureRandom.uuid

      ProcessedEvent.create!(event_id: event_id)

      expect {
        ProcessedEvent.create!(event_id: event_id)
      }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end
end

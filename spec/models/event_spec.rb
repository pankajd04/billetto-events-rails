
require "rails_helper"

RSpec.describe Event, type: :model do
  describe "validations" do
    it "is valid with an external ID and title" do
      event = Event.new(
        external_id: "event-test-001",
        title: "Test Event"
      )

      expect(event).to be_valid
    end

    it "requires an external ID" do
      event = Event.new(title: "Test Event")

      expect(event).not_to be_valid
    end

    it "requires a title" do
      event = Event.new(external_id: "event-test-002")

      expect(event).not_to be_valid
    end

    it "rejects duplicate external IDs" do
      Event.create!(
        external_id: "event-test-003",
        title: "First Event"
      )

      duplicate = Event.new(
        external_id: "event-test-003",
        title: "Second Event"
      )

      expect(duplicate).not_to be_valid
    end
  end
end

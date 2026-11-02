require 'rails_helper'

RSpec.describe EventVoteCount, type: :model do
  let(:event) do
    Event.create!(
      external_id: "test_event_#{SecureRandom.uuid}",
      title: "Test Event"
    )
  end

  subject(:event_vote_count) do
    described_class.new(
      event: event,
      upvotes_count: 0,
      downvotes_count: 0
    )
  end

  describe "associations" do
    it "belongs to an event" do
      association = described_class.reflect_on_association(:event)

      expect(association.macro).to eq(:belongs_to)
    end
  end

  describe "validations" do
    it "is valid with an event and valid counts" do
      expect(event_vote_count).to be_valid
    end

    it "does not allow negative upvote counts" do
      event_vote_count.upvotes_count = -1

      expect(event_vote_count).not_to be_valid
    end

    it "does not allow negative downvote counts" do
      event_vote_count.downvotes_count = -1

      expect(event_vote_count).not_to be_valid
    end

    it "does not allow multiple count records for the same event" do
      event_vote_count.save!

      duplicate = described_class.new(
        event: event,
        upvotes_count: 1,
        downvotes_count: 0
      )

      expect {
        duplicate.save!
      }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end
end

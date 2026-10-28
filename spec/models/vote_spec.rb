
require "rails_helper"

RSpec.describe Vote, type: :model do
  let(:event) do
    Event.create!(
      external_id: "vote-test-event",
      title: "Test Event"
    )
  end

  let(:vote) do
    Vote.new(
      event: event,
      clerk_user_id: "user_test_123",
      direction: "upvote"
    )
  end

  describe "validations" do
    it "is valid with valid attributes" do
      expect(vote).to be_valid
    end

    it "requires a Clerk user ID" do
      vote.clerk_user_id = nil

      expect(vote).not_to be_valid
    end

    it "accepts an upvote direction" do
      vote.direction = "upvote"

      expect(vote).to be_valid
    end

    it "accepts a downvote direction" do
      vote.direction = "downvote"

      expect(vote).to be_valid
    end

    it "rejects an invalid direction" do
      vote.direction = "invalid"

      expect(vote).not_to be_valid
    end

    it "allows only one vote per user per event" do
      vote.save!

      duplicate_vote = Vote.new(
        event: event,
        clerk_user_id: "user_test_123",
        direction: "downvote"
      )

      expect(duplicate_vote).not_to be_valid
    end

    
    it "allows an existing vote to change direction without creating another vote" do
      event = Event.create!(
        external_id: "vote-change-test",
        title: "Vote Change Test"
      )

      vote = Vote.create!(
        event: event,
        clerk_user_id: "user_change_test",
        direction: "upvote"
      )

      expect {
        vote.update!(direction: "downvote")
      }.not_to change(Vote, :count)

      expect(vote.reload.direction).to eq("downvote")
      expect(event.votes.where(direction: "upvote").count).to eq(0)
      expect(event.votes.where(direction: "downvote").count).to eq(1)
    end

  end
end

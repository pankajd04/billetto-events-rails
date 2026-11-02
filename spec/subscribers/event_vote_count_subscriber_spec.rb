require "rails_helper"

RSpec.describe EventVoteCountSubscriber do
  let(:event) do
  Event.create!(
        external_id: "test_event_#{SecureRandom.uuid}",
        title: "Test Event"
    )
    end
  let(:subscriber) { described_class.new }

  describe "#call" do
    context "when an event is upvoted" do
      it "increments the upvote count" do
        domain_event = EventUpvoted.new(
          data: {
            event_id: event.id,
            clerk_user_id: "user_101",
            previous_direction: nil,
            direction: "upvote"
          }
        )

        subscriber.call(domain_event)

        counts = EventVoteCount.find_by(event: event)

        expect(counts.upvotes_count).to eq(1)
        expect(counts.downvotes_count).to eq(0)
      end
    end

    context "when an event is downvoted" do
      it "increments the downvote count" do
        domain_event = EventDownvoted.new(
          data: {
            event_id: event.id,
            clerk_user_id: "user_102",
            previous_direction: nil,
            direction: "downvote"
          }
        )

        subscriber.call(domain_event)

        counts = EventVoteCount.find_by(event: event)

        expect(counts.upvotes_count).to eq(0)
        expect(counts.downvotes_count).to eq(1)
      end
    end

    context "when a user changes an upvote to a downvote" do
      it "decreases upvotes and increases downvotes" do
        EventVoteCount.create!(
          event: event,
          upvotes_count: 1,
          downvotes_count: 0
        )

        domain_event = EventDownvoted.new(
          data: {
            event_id: event.id,
            clerk_user_id: "user_103",
            previous_direction: "upvote",
            direction: "downvote"
          }
        )

        subscriber.call(domain_event)

        counts = EventVoteCount.find_by(event: event)

        expect(counts.upvotes_count).to eq(0)
        expect(counts.downvotes_count).to eq(1)
      end
    end

    context "when a user changes a downvote to an upvote" do
      it "decreases downvotes and increases upvotes" do
        EventVoteCount.create!(
          event: event,
          upvotes_count: 0,
          downvotes_count: 1
        )

        domain_event = EventUpvoted.new(
          data: {
            event_id: event.id,
            clerk_user_id: "user_104",
            previous_direction: "downvote",
            direction: "upvote"
          }
        )

        subscriber.call(domain_event)

        counts = EventVoteCount.find_by(event: event)

        expect(counts.upvotes_count).to eq(1)
        expect(counts.downvotes_count).to eq(0)
      end
    end

    context "when the same event is processed twice" do
      it "does not increment the count twice" do
        domain_event = EventUpvoted.new(
        data: {
            event_id: event.id,
            clerk_user_id: "user_105",
            previous_direction: nil,
            direction: "upvote"
        }
        )

        subscriber.call(domain_event)
        subscriber.call(domain_event)

        counts = EventVoteCount.find_by(event: event)

        expect(counts.upvotes_count).to eq(1)
        expect(counts.downvotes_count).to eq(0)
        expect(ProcessedEvent.count).to eq(1)
      end
    end
  end
end

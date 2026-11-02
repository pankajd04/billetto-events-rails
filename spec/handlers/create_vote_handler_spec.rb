
require "rails_helper"

RSpec.describe CreateVoteHandler do
  let(:event) do
    Event.create!(
      external_id: "test_event_#{SecureRandom.uuid}",
      title: "Test Event"
    )
  end

  let(:handler) { described_class.new }
  let(:user_id) { "test_user_101" }
  let(:event_store) { Rails.configuration.event_store }

  describe "#call" do
    context "when a user votes for the first time" do
      it "creates a vote and publishes an upvote event" do
        published_events = []

        allow(event_store).to receive(:publish).and_wrap_original do |original, domain_event, **options|
          published_events << [domain_event, options]
          original.call(domain_event, **options)
        end

        expect {
          result = handler.call(
            CreateVote.new(
              event_id: event.id,
              clerk_user_id: user_id,
              direction: "upvote"
            )
          )

          expect(result).to eq(:recorded)
        }.to change(Vote, :count).by(1)

        expect(Vote.last.direction).to eq("upvote")

        published_event, options = published_events.last

        expect(published_event).to be_a(EventUpvoted)
        expect(published_event.data).to include(
          event_id: event.id,
          clerk_user_id: user_id,
          previous_direction: nil,
          direction: "upvote"
        )

        expect(options[:stream_name]).to eq("event_#{event.id}_votes")
      end
    end

    context "when a user repeats the same vote" do
      it "does not create another vote or publish another event" do
        handler.call(
          CreateVote.new(
            event_id: event.id,
            clerk_user_id: user_id,
            direction: "upvote"
          )
        )

        expect(event_store).not_to receive(:publish)

        expect {
          result = handler.call(
            CreateVote.new(
              event_id: event.id,
              clerk_user_id: user_id,
              direction: "upvote"
            )
          )

          expect(result).to eq(:already_recorded)
        }.not_to change(Vote, :count)
      end
    end

    context "when a user changes their vote" do
      it "updates the existing vote direction and publishes a downvote event" do
        handler.call(
          CreateVote.new(
            event_id: event.id,
            clerk_user_id: user_id,
            direction: "upvote"
          )
        )

        published_events = []

        allow(event_store).to receive(:publish).and_wrap_original do |original, domain_event, **options|
          published_events << [domain_event, options]
          original.call(domain_event, **options)
        end

        expect {
          result = handler.call(
            CreateVote.new(
              event_id: event.id,
              clerk_user_id: user_id,
              direction: "downvote"
            )
          )

          expect(result).to eq(:recorded)
        }.not_to change(Vote, :count)

        expect(
          Vote.find_by(event: event, clerk_user_id: user_id).direction
        ).to eq("downvote")

        published_event, options = published_events.last

        expect(published_event).to be_a(EventDownvoted)
        expect(published_event.data).to include(
          event_id: event.id,
          clerk_user_id: user_id,
          previous_direction: "upvote",
          direction: "downvote"
        )

        expect(options[:stream_name]).to eq("event_#{event.id}_votes")
      end
    end

    context "when the direction is invalid" do
      it "does not create a vote or publish an event" do
        expect(event_store).not_to receive(:publish)

        expect {
          result = handler.call(
            CreateVote.new(
              event_id: event.id,
              clerk_user_id: user_id,
              direction: "invalid"
            )
          )

          expect(result).to eq(:invalid)
        }.not_to change(Vote, :count)
      end
    end

    context "when a user votes down for the first time" do
      it "publishes an EventDownvoted event" do
        published_events = []

        allow(event_store).to receive(:publish).and_wrap_original do |original, domain_event, **options|
          published_events << [domain_event, options]
          original.call(domain_event, **options)
        end

        result = handler.call(
          CreateVote.new(
            event_id: event.id,
            clerk_user_id: user_id,
            direction: "downvote"
          )
        )

        expect(result).to eq(:recorded)

        published_event, = published_events.last

        expect(published_event).to be_a(EventDownvoted)
        expect(published_event.data).to include(
          event_id: event.id,
          clerk_user_id: user_id,
          previous_direction: nil,
          direction: "downvote"
        )
      end
    end

    context "when event publishing fails" do
      it "rolls back the vote record" do
        allow(event_store).to receive(:publish)
          .and_raise(StandardError, "Event publishing failed")

        expect {
          handler.call(
            CreateVote.new(
              event_id: event.id,
              clerk_user_id: user_id,
              direction: "upvote"
            )
          )
        }.to raise_error(StandardError, "Event publishing failed")

        expect(
          Vote.where(event: event, clerk_user_id: user_id)
        ).not_to exist
      end
    end
  end
end

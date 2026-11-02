require "rails_helper"

RSpec.describe CreateVoteHandler, "concurrency", :no_transaction do
  self.use_transactional_tests = false  
  it "creates only one vote when the same user votes concurrently" do
    event = Event.create!(
      external_id: "concurrency_#{SecureRandom.uuid}",
      title: "Concurrency Test Event"
    )

    handler = CreateVoteHandler.new

    ready = Queue.new
    start = Queue.new

    threads = 2.times.map do
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          ready << true
          start.pop

          handler.call(
            CreateVote.new(
              event_id: event.id,
              clerk_user_id: "concurrent_user_123",
              direction: "upvote"
            )
          )
        end
      end
    end

    2.times { ready.pop }
    2.times { start << true }

    results = threads.map(&:value)

    expect(results.count(:recorded)).to eq(1)
    expect(results.count(:already_recorded)).to eq(1)

    votes = Vote.where(
      event_id: event.id,
      clerk_user_id: "concurrent_user_123"
    )

    expect(votes.count).to eq(1)
  ensure
    threads&.each { |thread| thread.kill if thread.alive? }
    ProcessedEvent.delete_all
    Vote.where(event_id: event&.id).delete_all if event
    EventVoteCount.where(event_id: event&.id).delete_all if event
    Event.where(id: event&.id).delete_all if event
  end
end

require "rails_event_store"
require "aggregate_root"
require "arkency/command_bus"

Rails.configuration.to_prepare do
  Rails.configuration.event_store = RailsEventStore::JSONClient.new
  Rails.configuration.command_bus = Arkency::CommandBus.new

  Rails.configuration.event_store.tap do |store|
    # Business-level subscriber
    store.subscribe(
      EventVoteCountSubscriber.new,
      to: [EventUpvoted, EventDownvoted]
    )

    # Event linking subscriptions
    store.subscribe_to_all_events(RailsEventStore::LinkByEventType.new)
    store.subscribe_to_all_events(RailsEventStore::LinkByCorrelationId.new)
    store.subscribe_to_all_events(RailsEventStore::LinkByCausationId.new)
  end

  # Command Bus registration
  Rails.configuration.command_bus.register(
    CreateVote,
    CreateVoteHandler.new
  )
end

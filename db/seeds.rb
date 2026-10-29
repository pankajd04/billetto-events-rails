# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

sample_events = [
  {
    external_id: "demo-event-001",
    title: "Ruby on Rails Developer Meetup",
    description: "A sample event for testing event listings and voting.",
    image_url: nil,
    starts_at: 7.days.from_now,
    event_url: "https://example.com/events/ruby-meetup"
  },
  {
    external_id: "demo-event-002",
    title: "Technology and Innovation Conference",
    description: "Explore software engineering and emerging technologies.",
    image_url: nil,
    starts_at: 14.days.from_now,
    event_url: "https://example.com/events/technology-conference"
  },
  {
    external_id: "demo-event-003",
    title: "Community Design Workshop",
    description: "A sample workshop event for testing the application.",
    image_url: nil,
    starts_at: 21.days.from_now,
    event_url: "https://example.com/events/design-workshop"
  }
]

sample_events.each do |attributes|
  Event.find_or_create_by!(external_id: attributes[:external_id]) do |event|
    event.assign_attributes(attributes)
  end
end

puts "Sample events ready: #{sample_events.length}"

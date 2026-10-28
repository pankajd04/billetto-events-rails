
module BillettoEvent
  class BillettoImporter
    def initialize(client: BillettoApi.new)
      @client = client
    end

    def call(limit: 10)
      response = @client.fetch_events(limit: limit)

      response.fetch("data", []).each do |item|
        Event.find_or_initialize_by(
          external_id: item.fetch("id").to_s
        ).tap do |event|
          event.assign_attributes(
            title: item["title"],
            description: item["description"],
            image_url: item["image_link"],
            starts_at: parse_date(item["startdate"]),
            ends_at: parse_date(item["enddate"]),
            event_url: item["url"],
            state: item["state"]
          )

          event.save!
        end
      end

      response
    end

    private

    def parse_date(value)
      return if value.blank?

      Time.iso8601(value)
    end
  end
end

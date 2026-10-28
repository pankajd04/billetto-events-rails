
require "net/http"
require "json"
require "uri"

module BillettoEvent
  class BillettoApi
    BASE_URL = "https://billetto.dk/api/v3/public/events"

    def fetch_events(limit: 10)
      uri = URI(BASE_URL)
      uri.query = URI.encode_www_form(limit: limit)

      response = request(uri)
      JSON.parse(response.body)
    end

    private

    def request(uri)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = 5
      http.read_timeout = 15

      request = Net::HTTP::Get.new(uri)
      request["Accept"] = "application/json"
      request["Api-Keypair"] = ENV['BILLETTO_API_KEYPAIR']

      response = http.request(request)

      unless response.is_a?(Net::HTTPSuccess)
        raise "Billetto API error: HTTP #{response.code}"
      end

      response
    end
  end
end

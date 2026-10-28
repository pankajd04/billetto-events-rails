
require "rails_helper"

RSpec.describe "Votes", type: :request do
  describe "POST /events/:event_id/vote" do
    it "redirects unauthenticated users" do
      event = Event.create!(
        external_id: "rspec-vote-test",
        title: "RSpec Vote Test"
      )

      expect {
        post "/events/#{event.id}/vote",
             params: { direction: "upvote" }
      }.not_to change(Vote, :count)

      expect(response).to have_http_status(:redirect)
    end
  end
end

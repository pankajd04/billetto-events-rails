
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

    it "dispatches a CreateVote command through the Command Bus for authenticated users" do
      event = Event.create!(
        external_id: "rspec-auth-vote-test",
        title: "RSpec Authenticated Vote Test"
      )

      clerk_session = double("Clerk session")
      clerk_client = double(
        "Clerk client",
        session: clerk_session,
        user_id: "clerk_user_123"
      )

      allow_any_instance_of(VotesController)
        .to receive(:clerk)
        .and_return(clerk_client)

      command_bus = Rails.configuration.command_bus

      expect(command_bus).to receive(:call) do |command|
        expect(command).to be_a(CreateVote)
        expect(command.event_id).to eq(event.id.to_s)
        expect(command.clerk_user_id).to eq("clerk_user_123")
        expect(command.direction).to eq("upvote")

        :recorded
      end

      post "/events/#{event.id}/vote",
           params: { direction: "upvote" }

      expect(response).to redirect_to(root_path)
      expect(flash[:notice]).to eq("Vote recorded.")
    end
  end
end

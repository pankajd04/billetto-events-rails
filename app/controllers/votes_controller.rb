
class VotesController < ApplicationController
  before_action :require_clerk_session!

  def create
    event = Event.find(params[:event_id])
    user_id = clerk.user_id
    direction = params[:direction]

    unless Vote::DIRECTIONS.include?(direction)
      return redirect_to root_path, alert: "Invalid vote."
    end

    vote = Vote.find_or_initialize_by(
      event: event,
      clerk_user_id: user_id
    )

    
    previous_direction = vote.direction

    if previous_direction == direction
      return redirect_to root_path, notice: "Vote already recorded."
    end

    ActiveRecord::Base.transaction do
      vote.direction = direction
      vote.save!

      event_data = {
        event_id: event.id,
        clerk_user_id: user_id,
        previous_direction: previous_direction,
        direction: direction
      }

      domain_event =
        if direction == "upvote"
          EventUpvoted.new(data: event_data)
        else
          EventDownvoted.new(data: event_data)
        end

      Rails.configuration.event_store.publish(
        domain_event,
        stream_name: "event_#{event.id}_votes"
      )
    end

    redirect_to root_path, notice: "Vote recorded."

  end

  private

  def require_clerk_session!
     Rails.logger.info(
        "Clerk auth diagnostic: session_present=#{clerk.session.present?}, " \
        "user_id_present=#{clerk.user_id.present?}, " \
        "request_format=#{request.format}"
      )
    return if clerk.session && clerk.user_id.present?
    sign_in_url = ENV['CLERK_SIGN_IN_URL']
    redirect_url = "http://localhost:3000/"

      redirect_to(
        "#{sign_in_url}?redirect_url=#{ERB::Util.url_encode(redirect_url)}",
        allow_other_host: true
      )
    # redirect_to sign_in_url, allow_other_host: true
  end
end

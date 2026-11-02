class CreateVoteHandler
  def call(command)
    return :invalid unless Vote::DIRECTIONS.include?(command.direction)

    event = Event.find(command.event_id)
    result = nil

    Event.transaction do
      # Lock the event row to serialize voting operations
      event.lock!

      vote = Vote.find_or_initialize_by(
        event: event,
        clerk_user_id: command.clerk_user_id
      )

      previous_direction = vote.direction

      if previous_direction == command.direction
        result = :already_recorded
      else
        vote.direction = command.direction
        vote.save!

        event_data = {
          event_id: event.id,
          clerk_user_id: command.clerk_user_id,
          previous_direction: previous_direction,
          direction: command.direction
        }

        domain_event =
          if command.direction == "upvote"
            EventUpvoted.new(data: event_data)
          else
            EventDownvoted.new(data: event_data)
          end

        Rails.configuration.event_store.publish(
          domain_event,
          stream_name: "event_#{event.id}_votes"
        )

        result = :recorded
      end
    end

    result
  end
end

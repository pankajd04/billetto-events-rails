
class EventVoteCountSubscriber
  def call(event)
    EventVoteCount.transaction do
      ProcessedEvent.create!(
        event_id: event.event_id
      )

      event_data = event.data

      counts = EventVoteCount.find_by(
        event_id: event_data[:event_id]
      )

      if counts.nil?
        # The vote has already been saved by the handler.
        # Initialize the projection from the current vote records.
        upvotes = Vote.where(
          event_id: event_data[:event_id],
          direction: "upvote"
        ).count

        downvotes = Vote.where(
          event_id: event_data[:event_id],
          direction: "downvote"
        ).count

        EventVoteCount.create!(
          event_id: event_data[:event_id],
          upvotes_count: upvotes,
          downvotes_count: downvotes
        )
      else
        counts.lock!

        previous_direction = event_data[:previous_direction]
        direction = event_data[:direction]

        if previous_direction == "upvote"
          counts.upvotes_count -= 1
        elsif previous_direction == "downvote"
          counts.downvotes_count -= 1
        end

        if direction == "upvote"
          counts.upvotes_count += 1
        elsif direction == "downvote"
          counts.downvotes_count += 1
        end

        counts.save!
      end
    end
  rescue ActiveRecord::RecordNotUnique
    Rails.logger.info("Event already processed: #{event.event_id}")
  end
end

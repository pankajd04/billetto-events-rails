class CreateVote
  attr_reader :event_id, :clerk_user_id, :direction

  def initialize(event_id:, clerk_user_id:, direction:)
    @event_id = event_id
    @clerk_user_id = clerk_user_id
    @direction = direction
  end
end
class EventsController < ApplicationController
  def index
    @events = Event.where.not(external_id: "test-001")
                   .order(starts_at: :asc)
  end
end
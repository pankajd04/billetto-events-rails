
Rails.application.routes.draw do
  mount RailsEventStore::Browser => "/res" if Rails.env.development?

  root "events#index"

  get "/dashboard", to: "dashboard#show"

  post "/events/:event_id/vote",
       to: "votes#create",
       as: :event_vote
end

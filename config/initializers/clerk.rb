Clerk.configure do |config|
  config.publishable_key = ENV["CLERK_PUBLISHABLE_KEY"]
  config.secret_key = ENV["CLERK_SECRET_KEY"]

  config.debug = true
  config.logger = Logger.new(STDOUT)
  config.excluded_routes = ["/events/*/vote"]
end
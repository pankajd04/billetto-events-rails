
class DashboardController < ApplicationController
  before_action :require_clerk_session!

  def show
  end

  private

  def require_clerk_session!
  return if clerk.session

  sign_in_url = ENV['CLERK_SIGN_IN_URL']
  if sign_in_url.present?
    redirect_to sign_in_url, allow_other_host: true
    # redirect_to "#{sign_in_url}?redirect_url=#{ERB::Util.url_encode('http://localhost:3000/dashboard')}", allow_other_host: true unless clerk.session
  else
    render plain: "Clerk sign-in URL is not configured", status: :internal_server_error
  end
end
end

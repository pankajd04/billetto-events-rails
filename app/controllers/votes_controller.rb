
class VotesController < ApplicationController
  before_action :require_clerk_session!

  # Reverification preset is set to `LAX`
  # before_action :require_reverification!, only: :destroy, preset: Clerk::StepUp::Preset::LAX


  def create
    command = CreateVote.new(
      event_id: params[:event_id],
      clerk_user_id: clerk.user_id,
      direction: params[:direction]
    )

    result = Rails.configuration.command_bus.call(command)

    case result
    when :recorded
      redirect_to root_url, notice: "Vote recorded."
    when :already_recorded
      redirect_to root_url, notice: "Vote already recorded."
    else
      redirect_to root_url, alert: "Invalid vote."
    end
  end

  private

  # def require_clerk_session!
  #   authenticated = clerk.session && clerk.user_id.present?

  #   Rails.logger.info(
  #     "Clerk auth diagnostic: " \
  #     "session_present=#{clerk.session.present?}, " \
  #     "user_id_present=#{clerk.user_id.present?}, " \
  #     "request_format=#{request.format}"
  #   )

  #   return if authenticated

  #   sign_in_url = ENV["CLERK_SIGN_IN_URL"]
    
  #   if sign_in_url.blank?
  #     redirect_to root_url, alert: "Clerk sign-in URL is not configured."
  #     return
  #   end
    
  #   redirect_to sign_in_url, allow_other_host: true


  #   # redirect_to(
  #   #   "#{sign_in_url}?redirect_url=#{ERB::Util.url_encode(root_url)}",
  #   #   allow_other_host: true
  #   # )
  # end

  def require_clerk_session!
    Rails.logger.info "===== CLERK DEBUG ====="
    Rails.logger.info "Session: #{clerk.session.inspect}"
    Rails.logger.info "User ID: #{clerk.user_id.inspect}"
    Rails.logger.info "Cookies: #{request.cookies.keys.inspect}"
    Rails.logger.info "AUTH REASON: #{request.headers['X-Clerk-Auth-Reason']}"
    Rails.logger.info "======================="

    return if clerk.session && clerk.user_id.present?

    redirect_to "/login"
  end
end

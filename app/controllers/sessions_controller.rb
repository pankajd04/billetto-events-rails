class SessionsController < ApplicationController
  def new
    sign_in_url = ENV["CLERK_SIGN_IN_URL"]

    @clerk_sign_in_url = "#{sign_in_url}"  
  end
end
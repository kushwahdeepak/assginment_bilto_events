class ApplicationController < ActionController::Base
  helper_method :current_user, :user_signed_in?

  def sign_out
    cookies.delete(:mock_clerk_user_id)
    reset_session
    redirect_to root_path
  end

  def current_user
    if Rails.env.test? && cookies[:mock_clerk_user_id].present?
      # Return mock user object or string ID
      cookies[:mock_clerk_user_id]
    else
      session[:clerk_user_id]
    end
  end

  def user_signed_in?
    current_user.present?
  end
end
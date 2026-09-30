require "clerk/configuration"
require "clerk/error"
require "clerk/sdk"
require "clerk/jwks_cache"
require "faraday"
require "jwt"

module ClerkAuthenticatable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_clerk_user!
  end

  private

  def authenticate_clerk_user!
    return if current_user_id

    render json: { error: "Unauthorized" }, status: :unauthorized
  end

  def current_user_id
    return @current_user_id if defined?(@current_user_id)

    authorization = request.headers["Authorization"].to_s.split(/\s+/)
    return nil unless authorization.length == 2 && authorization.first.casecmp("Bearer").zero?

    token = authorization.last

    Clerk::Configuration.default
    payload = Clerk::SDK.new.verify_token(token)
    @current_user_id = payload["sub"].presence
  rescue Clerk::Error, Clerk::ConfigurationError, JWT::DecodeError, Faraday::Error => e
    Rails.logger.warn("Clerk Auth Error (#{e.class}): #{e.message}")
    nil
  end
end

class VotesController < ApplicationController
  include ClerkAuthenticatable

  def create
    return render json: { error: "Event not found" }, status: :not_found unless Event.exists?(id: params[:event_id])

    vote_typ = params[:type]

    command_class = case vote_typ
    when "upvote"
      EventsDomain::Upvote
    when "downvote"
      EventsDomain::Downvote
    else
      return render json: { errors: ["Type must be upvote or downvote"] }, status: :unprocessable_entity
    end

    command = command_class.new(event_id: params[:event_id].to_s, user_id: current_user_id)

    if Rails.configuration.command_bus.call(command)
      if cookies[:mock_clerk_user_id].present? && request.headers["Accept"].to_s.include?("text/html")
        redirect_to event_path(params[:event_id])
      else
        render json: { status: "success" }, status: :created
        end
    else
      render json: { errors: command.errors.full_messages }, status: :unprocessable_entity
    end
  end
end

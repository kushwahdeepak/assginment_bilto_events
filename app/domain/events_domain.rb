require_relative "../read_models/read_models/vote_projector"

module EventsDomain
  def self.subscriptions
    {
      EventsDomain::EventUpvoted => [::ReadModels::VoteProjector.new],
      EventsDomain::EventDownvoted => [::ReadModels::VoteProjector.new]
    }
  end
end

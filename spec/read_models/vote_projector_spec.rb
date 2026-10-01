require 'rails_helper'

RSpec.describe ReadModels::VoteProjector do
  let(:event_id) { "indore_event_999" }

  it "increments upvotes count upon receiving EventUpvoted" do
    event = EventsDomain::EventUpvoted.strict(data: { event_id: event_id, user_id: "user_indore_1" })
    subject.call(event)

    stat = EventStat.find_by(event_id: event_id)
    expect(stat.upvotes_count).to eq(1)
    expect(stat.downvotes_count).to eq(0)
  end

  it "increments downvotes while preserving the upvote count" do
    projector = described_class.new
    projector.call(EventsDomain::EventUpvoted.strict(data: { event_id: event_id, user_id: "user_indore_1" }))
    projector.call(EventsDomain::EventDownvoted.strict(data: { event_id: event_id, user_id: "user_indore_2" }))

    stat = EventStat.find_by!(event_id: event_id)
    expect(stat.upvotes_count).to eq(1)
    expect(stat.downvotes_count).to eq(1)
  end
end

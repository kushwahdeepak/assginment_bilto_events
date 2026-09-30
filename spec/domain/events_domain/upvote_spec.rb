require 'rails_helper'

RSpec.describe EventsDomain::Upvote do
  let(:event_store) { Rails.configuration.event_store }

  it "publishes EventUpvoted event" do
    command = described_class.new(event_id: "indore_event_1", user_id: "user_indore_100")

    expect(command.call).to be(true)

    stored_event = event_store.read.stream("Event$indore_event_1").to_a.last
    expect(stored_event).to be_a(EventsDomain::EventUpvoted)
    expect(stored_event.data).to eq(event_id: "indore_event_1", user_id: "user_indore_100")
    expect(event_store.read.stream("User$user_indore_100").to_a.last.event_id).to eq(stored_event.event_id)
  end
end

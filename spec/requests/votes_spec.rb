require 'rails_helper'

RSpec.describe "Votes API", type: :request do
  let(:event) do
    Event.create!(
      external_id: "billetto_indore_vote_test",
      title: "Indore Food Festival",
      start_date: Time.zone.parse("2026-10-10 19:00 +05:30")
    )
  end

  context "unauthenticated" do
    it "returns 401 unauthorized" do
      post "/events/#{event.id}/votes", params: { type: "upvote" }

      expect(response).to have_http_status(:unauthorized)
    end

    it "rejects authorization headers that are not bearer tokens" do
      post "/events/#{event.id}/votes",
        params: { type: "upvote" },
        headers: { "Authorization" => "Basic invalid-token" }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  context "authenticated" do
    before do
      allow_any_instance_of(Clerk::SDK).to receive(:verify_token)
        .with("test-token")
        .and_return({ "sub" => "user_indore_12345" })
    end

    it "executes upvote successfully" do
      post "/events/#{event.id}/votes", params: { type: "upvote" }, headers: { "Authorization" => "Bearer test-token" }

      expect(response).to have_http_status(:created)
      expect(EventStat.find_by!(event_id: event.id.to_s).upvotes_count).to eq(1)

      stored_vote = Rails.configuration.event_store.read.stream("User$user_indore_12345").to_a.last
      expect(stored_vote).to be_a(EventsDomain::EventUpvoted)
      expect(stored_vote.data).to include(event_id: event.id.to_s, user_id: "user_indore_12345")
    end

    it "executes a downvote successfully" do
      post "/events/#{event.id}/votes", params: { type: "downvote" }, headers: { "Authorization" => "Bearer test-token" }

      expect(response).to have_http_status(:created)
      expect(EventStat.find_by!(event_id: event.id.to_s).downvotes_count).to eq(1)
      expect(Rails.configuration.event_store.read.stream("User$user_indore_12345").to_a.last)
        .to be_a(EventsDomain::EventDownvoted)
    end

    it "rejects unsupported vote types" do
      post "/events/#{event.id}/votes", params: { type: "neutral" }, headers: { "Authorization" => "Bearer test-token" }

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "does not accept a Clerk token without a subject claim" do
      allow_any_instance_of(Clerk::SDK).to receive(:verify_token).with("empty-subject").and_return({})

      post "/events/#{event.id}/votes", params: { type: "upvote" }, headers: { "Authorization" => "Bearer empty-subject" }

      expect(response).to have_http_status(:unauthorized)
    end

    it "does not create votes for nonexistent events" do
      post "/events/999999/votes", params: { type: "upvote" }, headers: { "Authorization" => "Bearer test-token" }

      expect(response).to have_http_status(:not_found)
      expect(EventStat.count).to eq(0)
    end
  end
end

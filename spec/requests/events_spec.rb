require 'rails_helper'

RSpec.describe "Events API and pages", type: :request do
  let!(:event) do
    Event.create!(
      external_id: "billetto_indore_event_1",
      title: "Indore Heritage Food Festival",
      description: "Local food and music near Rajwada Palace, Indore, Madhya Pradesh.",
      start_date: Time.zone.parse("2026-10-10 19:00 +05:30"),
      image_url: "https://example.test/indore-food-festival.jpg"
    )
  end

  it "renders an HTML listing with event details and vote totals" do
    EventStat.create!(event_id: event.id.to_s, upvotes_count: 2, downvotes_count: 1)

    get "/"

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("text/html")
    expect(response.body).to include("Indore Heritage Food Festival", "Rajwada Palace, Indore", "2", "1")
  end

  it "returns event details and vote counts as JSON" do
    EventStat.create!(event_id: event.id.to_s, upvotes_count: 2, downvotes_count: 1)

    get "/events.json"

    expect(response).to have_http_status(:ok)
    payload = JSON.parse(response.body).fetch("events").first
    expect(payload).to include("id" => event.id, "title" => "Indore Heritage Food Festival", "upvotes" => 2, "downvotes" => 1)
  end

  it "paginates the event index and caps page size" do
    second_event = Event.create!(external_id: "billetto_indore_event_2", title: "Indore Street Food Walk", start_date: event.start_date + 1.day)

    get "/events.json", params: { page: 2, per_page: 1 }

    expect(response).to have_http_status(:ok)
    payload = JSON.parse(response.body)
    expect(payload.fetch("events").map { |item| item.fetch("id") }).to eq([second_event.id])
    expect(payload.fetch("pagination")).to include("page" => 2, "per_page" => 1, "total_events" => 2, "total_pages" => 2)

    get "/events.json", params: { per_page: 1_000 }
    expect(JSON.parse(response.body).dig("pagination", "per_page")).to eq(100)
  end

  it "returns an event as JSON from the show endpoint" do
    get "/events/#{event.id}.json"

    expect(response).to have_http_status(:ok)
    payload = JSON.parse(response.body).fetch("event")
    expect(payload).to include("title" => "Indore Heritage Food Festival", "upvotes" => 0, "downvotes" => 0)
  end
end

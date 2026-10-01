require 'rails_helper'

RSpec.describe BillettoApi::IngestEvents do
  let(:api_url) { "https://billetto.dk/api/v3/public/events?limit=100" }
  let(:mock_response) do
    JSON.generate({
      data: [
        {
          id: "billetto_indore_food_festival",
          title: "Indore Heritage Food Festival",
          description: "Local food, music, and culture near Rajwada Palace in Indore, Madhya Pradesh.",
          startdate: "2026-10-10T19:00:00+05:30",
          image_link: "https://example.test/indore-food-festival.jpg"
        }
      ]
    })
  end

  before do
    stub_request(:get, api_url)
      .with(headers: { 'Api-Keypair' => 'test_key:test_secret' })
      .to_return(status: 200, body: mock_response, headers: { 'Content-Type' => 'application/json' })
  end

  it "ingests events from external API correctly" do
    expect {
      described_class.call(api_key: 'test_key', api_secret: 'test_secret')
    }.to change(Event, :count).by(1)

    event = Event.find_by(external_id: "billetto_indore_food_festival")
    expect(event.title).to eq("Indore Heritage Food Festival")
    expect(event.description).to include("Rajwada Palace", "Indore, Madhya Pradesh")
    expect(event.start_date).to eq(Time.zone.parse("2026-10-10 19:00 +05:30"))
    expect(event.image_url).to eq("https://example.test/indore-food-festival.jpg")
  end

  it "updates existing events on subsequent imports instead of duplicating them" do
    Event.create!(external_id: "billetto_indore_food_festival", title: "Previous Indore listing", start_date: Time.zone.parse("2026-10-10 19:00 +05:30"))

    expect { described_class.call(api_key: 'test_key', api_secret: 'test_secret') }.not_to change(Event, :count)
    expect(Event.find_by!(external_id: "billetto_indore_food_festival").title).to eq("Indore Heritage Food Festival")
  end

  it "returns false when the API responds unsuccessfully" do
    stub_request(:get, api_url).with(headers: { 'Api-Keypair' => 'test_key:test_secret' }).to_return(status: 503)

    expect(described_class.call(api_key: 'test_key', api_secret: 'test_secret')).to be(false)
    expect(Event.count).to eq(0)
  end

  it "skips invalid event records and imports the valid records" do
    stub_request(:get, api_url).with(headers: { 'Api-Keypair' => 'test_key:test_secret' }).to_return(
      status: 200,
      body: JSON.generate(data: [
        { id: "billetto_indore_valid", attributes: { title: "Indore Food Walk", start_date: "2026-10-10T19:00:00+05:30" } },
        { id: "billetto_indore_missing_date", attributes: { title: "Indore listing without a date" } }
      ])
    )

    expect(described_class.call(api_key: 'test_key', api_secret: 'test_secret')).to be(true)
    expect(Event.count).to eq(1)
    expect(Event.find_by!(external_id: "billetto_indore_valid").title).to eq("Indore Food Walk")
  end

  it "returns false for malformed JSON" do
    stub_request(:get, api_url).with(headers: { 'Api-Keypair' => 'test_key:test_secret' }).to_return(status: 200, body: "not json")

    expect(described_class.call(api_key: 'test_key', api_secret: 'test_secret')).to be(false)
    expect(Event.count).to eq(0)
  end

  it "returns false when the response has an unexpected shape" do
    stub_request(:get, api_url).with(headers: { 'Api-Keypair' => 'test_key:test_secret' }).to_return(status: 200, body: "null")

    expect(described_class.call(api_key: 'test_key', api_secret: 'test_secret')).to be(false)
    expect(Event.count).to eq(0)
  end

  it "sends the API keypair in the documented header" do
    stub_request(:get, api_url)
      .with(headers: { "Accept" => "application/json", "Api-Keypair" => "test_key:test_secret" })
      .to_return(status: 200, body: JSON.generate(data: []))

    expect(described_class.call(api_key: "test_key", api_secret: "test_secret")).to be(true)
  end

  it "follows Billetto pagination to import events from later pages" do
    second_page = "https://billetto.dk/api/v3/public/events?limit=100&after=next-page"
    stub_request(:get, api_url)
      .with(headers: { "Api-Keypair" => "test_key:test_secret" })
      .to_return(status: 200, body: JSON.generate(data: [
        { id: "billetto_indore_page_one", title: "Indore Food Walk", startdate: "2026-10-10T19:00:00+05:30" }
      ], next_url: second_page))
    stub_request(:get, second_page)
      .with(headers: { "Api-Keypair" => "test_key:test_secret" })
      .to_return(status: 200, body: JSON.generate(data: [
        { id: "billetto_indore_page_two", title: "Indore Heritage Festival", startdate: "2026-10-11T19:00:00+05:30" }
      ]))

    expect(described_class.call(api_key: "test_key", api_secret: "test_secret")).to be(true)
    expect(Event.find_by!(external_id: "billetto_indore_page_two").title).to eq("Indore Heritage Festival")
  end

  it "returns false when Billetto provides a malformed pagination URL" do
    stub_request(:get, api_url)
      .with(headers: { "Api-Keypair" => "test_key:test_secret" })
      .to_return(status: 200, body: JSON.generate(data: [], next_url: "http://[invalid"))

    expect(described_class.call(api_key: "test_key", api_secret: "test_secret")).to be(false)
    expect(Event.count).to eq(0)
  end
end

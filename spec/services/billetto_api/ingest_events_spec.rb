require 'rails_helper'

RSpec.describe BillettoApi::IngestEvents do
  let(:api_url) { "https://billetto.dk/api/v3/public/events?limit=100" }
  let(:mock_response) do
    JSON.generate({
      data: [
        {
          id: "billetto_123",
          title: "Music Festival",
          description: "Fun outdoor event",
          startdate: "2026-10-01T18:00:00Z",
          image_link: "https://example.com/image.jpg"
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

    event = Event.find_by(external_id: "billetto_123")
    expect(event.title).to eq("Music Festival")
    expect(event.image_url).to eq("https://example.com/image.jpg")
  end

  it "updates existing events on subsequent imports instead of duplicating them" do
    Event.create!(external_id: "billetto_123", title: "Old title", start_date: Time.zone.parse("2026-10-01 18:00"))

    expect { described_class.call(api_key: 'test_key', api_secret: 'test_secret') }.not_to change(Event, :count)
    expect(Event.find_by!(external_id: "billetto_123").title).to eq("Music Festival")
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
        { id: "valid_event", attributes: { title: "Valid", start_date: "2026-10-01T18:00:00Z" } },
        { id: "invalid_event", attributes: { title: "Missing date" } }
      ])
    )

    expect(described_class.call(api_key: 'test_key', api_secret: 'test_secret')).to be(true)
    expect(Event.count).to eq(1)
    expect(Event.find_by!(external_id: "valid_event").title).to eq("Valid")
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
        { id: "page_one", title: "First", startdate: "2026-10-01T18:00:00Z" }
      ], next_url: second_page))
    stub_request(:get, second_page)
      .with(headers: { "Api-Keypair" => "test_key:test_secret" })
      .to_return(status: 200, body: JSON.generate(data: [
        { id: "page_two", title: "New event", startdate: "2026-10-02T18:00:00Z" }
      ]))

    expect(described_class.call(api_key: "test_key", api_secret: "test_secret")).to be(true)
    expect(Event.find_by!(external_id: "page_two").title).to eq("New event")
  end

  it "returns false when Billetto provides a malformed pagination URL" do
    stub_request(:get, api_url)
      .with(headers: { "Api-Keypair" => "test_key:test_secret" })
      .to_return(status: 200, body: JSON.generate(data: [], next_url: "http://[invalid"))

    expect(described_class.call(api_key: "test_key", api_secret: "test_secret")).to be(false)
    expect(Event.count).to eq(0)
  end
end

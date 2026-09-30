require "json"
require "faraday"
require "set"
require "uri"

module BillettoApi
  class IngestEvents
    InvalidResponse = Class.new(StandardError)
    API_URL = "https://billetto.dk/api/v3/public/events"
    PAGE_LIMIT = 100
    MAX_PAGES = 100

    def self.call(api_key: ENV["BILLETTO_API_KEY"], api_secret: ENV["BILLETTO_API_SECRET"])
      new(api_key: api_key, api_secret: api_secret).call
    end

    def initialize(api_key:, api_secret: nil)
      @api_key = api_key
      @api_secret = api_secret
    end

    def call
      events = fetch_all_events

      Event.transaction do
        events.each do |event_data|
          raise InvalidResponse, "Expected each event to be an object" unless event_data.is_a?(Hash)

          Event.find_or_initialize_by(external_id: event_data["id"]).tap do |event|
            attributes = event_data["attributes"] || event_data
            raise InvalidResponse, "Expected event attributes to be an object" unless attributes.is_a?(Hash)

            event.title = attributes["title"]
            event.description = attributes["description"]
            event.start_date = attributes["start_date"] || attributes["startdate"] || attributes["start"] || attributes["starts_at"] || attributes["start_time"]
            event.image_url = attributes["image_url"] || attributes["image_link"]

            if event.valid?
              event.save!
            else
              Rails.logger.warn(
                "Skipping invalid Billetto event #{event.external_id.inspect}: #{event.errors.full_messages.join(', ')}"
              )
            end
          end
        end
      end
      true
    rescue Faraday::Error, JSON::ParserError, URI::Error, KeyError, TypeError, ActiveRecord::RecordInvalid, InvalidResponse => e
      Rails.logger.error("Billetto API ingestion failed: #{e.message}")
      false
    end

    private

    def fetch_all_events
      events = []
      next_url = "#{API_URL}?limit=#{PAGE_LIMIT}"
      visited_urls = Set.new

      MAX_PAGES.times do
        raise InvalidResponse, "Billetto pagination repeated a page URL" unless visited_urls.add?(next_url)

        response = Faraday.get(next_url) do |req|
          if credentials_configured?
            req.headers["Api-Keypair"] = "#{@api_key}:#{@api_secret}"
          end
          req.headers["Accept"] = "application/json"
        end

        unless response.success?
          Rails.logger.warn("Billetto API returned HTTP #{response.status}")
          raise InvalidResponse, "Billetto API returned HTTP #{response.status}"
        end

        data = JSON.parse(response.body)
        raise InvalidResponse, "Expected an object response" unless data.is_a?(Hash)

        page_events = data.fetch("data")
        raise InvalidResponse, "Expected the API data field to be an array" unless page_events.is_a?(Array)

        events.concat(page_events)
        next_url = data["next_url"]
        return events if next_url.blank?

        next_url = URI.join(API_URL, next_url).to_s
        uri = URI.parse(next_url)
        unless uri.scheme == "https" && uri.host == URI.parse(API_URL).host && uri.path == URI.parse(API_URL).path
          raise InvalidResponse, "Billetto returned an invalid pagination URL"
        end
      end

      raise InvalidResponse, "Billetto pagination exceeded #{MAX_PAGES} pages"
    end

    def credentials_configured?
      @api_key.present? && @api_secret.present? && @api_key != "replace_me" && @api_secret != "replace_me"
    end
  end
end

require "rails_event_store"
require "ruby_event_store"

class Fact < RubyEventStore::Event
  def self.strict(data:)
    new(data: data)
  end
end

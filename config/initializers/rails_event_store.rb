require "rails_event_store"
require "ruby_event_store"
require "ruby_event_store/active_record"
require "arkency/command_bus"
require_relative "../../lib/command"
require_relative "../../lib/fact"
require_relative "../../lib/application_subscriptions"

Rails.configuration.to_prepare do
  repository = RubyEventStore::ActiveRecord::EventRepository.new(serializer: RubyEventStore::NULL)
  event_store = RailsEventStore::Client.new(repository: repository)
  command_bus = Arkency::CommandBus.new

  Rails.configuration.event_store = event_store
  Rails.configuration.command_bus = command_bus

  ApplicationSubscriptions.handlers.each do |event, subscribers|
    Array(subscribers).each do |subscriber|
      event_store.subscribe(subscriber, to: [event])
    end
  end
end
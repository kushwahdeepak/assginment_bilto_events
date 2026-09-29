require "rails_event_store"
require "arkency/command_bus"
module Command
  module Executable
    extend ActiveSupport::Concern
    include ActiveModel::Model
    include ActiveModel::Attributes

    def event_store
      Rails.configuration.event_store
    end

    def command_bus
      Rails.configuration.command_bus
    end
  end

  module Handler
    extend ActiveSupport::Concern

    included do
      def event_store
        Rails.configuration.event_store
      end

      def command_bus
        Rails.configuration.command_bus
      end
    end
  end
end
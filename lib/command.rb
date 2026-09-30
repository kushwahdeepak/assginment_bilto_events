require "active_support/concern"
require "active_model"

module Command
  module Executable
    extend ActiveSupport::Concern
    include ActiveModel::Model
    include ActiveModel::Attributes

    def event_store
      Rails.configuration.event_store
    end
  end
end

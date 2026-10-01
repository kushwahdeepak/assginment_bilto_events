class SyncBillettoEventsJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info("Sync started at #{Time.current}")
    success = BillettoApi::IngestEvents.call
    
    if success
      Rails.logger.info("Sync completed successfully.")
    else
      Rails.logger.error("Sync failed.")
    end
  end
end

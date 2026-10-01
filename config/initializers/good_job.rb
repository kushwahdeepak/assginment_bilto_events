Rails.application.configure do
  config.good_job.cron = {
    sync_billetto_events: {
      cron: "0 0 * * *",
      class: "SyncBillettoEventsJob"
    }
  }
end

module ReadModels
  class VoteProjector
    def call(event)
      counter = case event
      when EventsDomain::EventUpvoted then :upvotes_count
      when EventsDomain::EventDownvoted then :downvotes_count
      else return
      end

      EventStat.transaction do
        event_id = event.data.fetch(:event_id)
        stat = EventStat.find_by(event_id: event_id) || EventStat.create_or_find_by!(event_id: event_id)
        stat.with_lock { stat.increment!(counter) }
      end
    end
  end
end
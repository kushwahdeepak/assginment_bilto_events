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
        user_id = event.data.fetch(:user_id)
        user_events = Rails.configuration.event_store.read.stream("User$#{user_id}").to_a
        previous_vote = user_events.reverse.find do |e|
          e.data[:event_id].to_s == event_id.to_s && e.event_id != event.event_id
        end
        stat = EventStat.find_by(event_id: event_id) || EventStat.create_or_find_by!(event_id: event_id)
        stat.with_lock do 
          stat.increment!(counter)
          
          if previous_vote
            if event.is_a?(EventsDomain::EventUpvoted) && previous_vote.event_type == "EventsDomain::EventDownvoted"
              stat.decrement!(:downvotes_count)
            elsif event.is_a?(EventsDomain::EventDownvoted) && previous_vote.event_type == "EventsDomain::EventUpvoted"
              stat.decrement!(:upvotes_count)
            end
          end
        end
      end
    end
  end
end
module EventsDomain
  class Upvote
    include Command::Executable

    attribute :event_id, :string
    attribute :user_id, :string

    validates :event_id, :user_id, presence: true

    def call
      return false unless valid?

      event = EventUpvoted.strict(data: { event_id: event_id, user_id: user_id })
      event_store.publish(event, stream_name: event.stream_names.first)
      event_store.link(event.event_id, stream_name: event.stream_names.last)
      true
    end
  end
end

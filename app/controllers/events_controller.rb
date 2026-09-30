class EventsController < ApplicationController
  DEFAULT_PAGE_SIZE = 24
  MAX_PAGE_SIZE = 100

  def index
    @page = positive_integer_param(:page, default: 1)
    @per_page = [positive_integer_param(:per_page, default: DEFAULT_PAGE_SIZE), MAX_PAGE_SIZE].min
    @total_events = Event.count
    @total_pages = (@total_events.to_f / @per_page).ceil
    @events = Event.order(:start_date, :id).limit(@per_page).offset((@page - 1) * @per_page)
    @event_stats = EventStat.where(event_id: @events.map { |event| event.id.to_s }).index_by(&:event_id)

    respond_to do |format|
      format.html
      format.json do
        render json: {
          events: @events.map { |event| event_payload(event) },
          pagination: { page: @page, per_page: @per_page, total_events: @total_events, total_pages: @total_pages }
        }
      end
    end
  end

  def show
    @event = Event.find(params[:id])
    @event_stat = EventStat.find_by(event_id: @event.id.to_s)

    respond_to do |format|
      format.html
      format.json { render json: { event: event_payload(@event, @event_stat) } }
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Not found" }, status: :not_found
  end

  private

  def positive_integer_param(key, default:)
    value = Integer(params[key], 10)
    value.positive? ? value : default
  rescue ArgumentError, TypeError
    default
  end

  def event_payload(event, stat = @event_stats&.[](event.id.to_s))
    {
      id: event.id,
      title: event.title,
      description: event.description,
      start_date: event.start_date,
      image_url: event.image_url,
      upvotes: stat&.upvotes_count || 0,
      downvotes: stat&.downvotes_count || 0
    }
  end
end

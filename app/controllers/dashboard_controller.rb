class DashboardController < ApplicationController
  before_action :set_links, only: [:index]

  def index
    set_cards_info
    table_data
  end

  def generate_short_url
    link = Link.find_or_initialize_by(url: params[:url])

    if link.persisted? || link.save
      @short_url = link.create_short_url
    else
      @errors = link.errors.full_messages
    end

    set_links
    set_cards_info
    # Render pagination links against the dashboard path (not this POST action)
    # and without the POST params, so page links stay valid.
    table_data(pagy_request: { base_url: request.base_url, path: dashboard_path, params: {} })

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to dashboard_path }
    end
  end

  private

  def set_links
    @links = Link.all
  end

  def set_cards_info
    @total_links = @links.count
    @total_clicks = ClickEvent.count
    @today_clicks = ClickEvent.where("created_at >= ?", Time.zone.now.beginning_of_day).count
    @link_with_most_clicks = @links.joins(:click_events).group("links.id").order("COUNT(click_events.id) DESC").first
  end

  def table_data(pagy_request: nil)
    options = { limit: 5 }
    options[:request] = pagy_request if pagy_request

    # Pagy is handed the ActiveRecord relation, not an array, so LIMIT/OFFSET
    # reach Postgres. Mapping first loaded every link on every dashboard
    # render just to display five of them.
    @pagy, links = pagy(@links, **options)

    @table_data = links.map do |link|
      {
        code: link.short_code,
        short_url: link.create_short_url,
        url: link.url,
        clicks: link.click_events_count.to_s,
        created_at: link.created_at.strftime("%Y-%m-%d %H:%M:%S")
      }
    end
  end
end

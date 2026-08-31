class DashboardController < ApplicationController
  before_action :set_links, only: [:index]

  def index
    set_cards_info
    table_data
  end

  def generate_short_url
    link = Link.find_or_create_by(url: params[:url])
    @short_url = link.create_short_url

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
    @today_clicks = ClickEvent.where('created_at >= ?', Time.zone.now.beginning_of_day).count
    @link_with_most_clicks = @links.joins(:click_events).group('links.id').order('COUNT(click_events.id) DESC').first
  end

  def table_data(pagy_request: nil)
    @table_data = @links.map do |link|
      {
        code: link.short_code,
        short_url: link.create_short_url,
        url: link.url,
        clicks: link.click_events_count.to_s,
        created_at: link.created_at.strftime("%Y-%m-%d %H:%M:%S")
      }
    end

    options = { limit: 5 }
    options[:request] = pagy_request if pagy_request
    @pagy, @table_data = pagy(@table_data, **options)
  end
end

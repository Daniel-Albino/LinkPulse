require "rails_helper"

RSpec.describe "Dashboard", type: :request do
  describe "GET /dashboard" do
    it "responds successfully" do
      get dashboard_path

      expect(response).to have_http_status(:ok)
    end

    it "shows the empty state when there are no links" do
      get dashboard_path

      expect(response.body).to include("No links found.")
    end

    it "pushes the pagination down to SQL instead of loading every link" do
      create_list(:link, 7)

      queries = []
      subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |*, payload|
        queries << payload[:sql]
      end
      get dashboard_path
      ActiveSupport::Notifications.unsubscribe(subscriber)

      # If the controller mapped @links before paginating, the page query
      # would come back without a LIMIT and every row would be instantiated.
      link_selects = queries.grep(/SELECT.+FROM "links"/i)
      expect(link_selects).to be_present
      expect(link_selects).to include(a_string_matching(/LIMIT/i))
    end

    it "paginates to five links per page" do
      create_list(:link, 7)

      get dashboard_path

      expect(response.body).to include("7") # total count rendered by Pagy
      get "#{dashboard_path}?page=2"
      expect(response).to have_http_status(:ok)
    end

    it "shows the click count from the counter cache" do
      link = create(:link)
      create_list(:click_event, 3, link: link)

      get dashboard_path

      expect(response.body).to include(link.short_code)
      expect(response.body).to match(/>\s*3\s*</)
    end
  end

  describe "POST /dashboard/generate_short_url" do
    it "creates a link for a valid URL" do
      expect do
        post dashboard_generate_short_url_path, params: { url: "https://example.com/foo" }
      end.to change(Link, :count).by(1)
    end

    it "returns the short URL in the turbo stream response" do
      post dashboard_generate_short_url_path,
           params: { url: "https://example.com/foo" },
           as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(Link.last.short_code)
    end

    it "reuses the existing link when the URL was already shortened" do
      existing = create(:link, url: "https://example.com/foo")

      expect do
        post dashboard_generate_short_url_path,
             params: { url: "https://example.com/foo" },
             as: :turbo_stream
      end.not_to change(Link, :count)

      expect(response.body).to include(existing.short_code)
    end

    it "does not create anything for an invalid URL" do
      expect do
        post dashboard_generate_short_url_path, params: { url: "batatas" }
      end.not_to change(Link, :count)
    end

    it "shows the validation error instead of failing silently" do
      post dashboard_generate_short_url_path,
           params: { url: "batatas" },
           as: :turbo_stream

      expect(response.body).to include("must be a valid http or https URL")
    end

    it "never renders a short URL with an empty code" do
      post dashboard_generate_short_url_path,
           params: { url: "batatas" },
           as: :turbo_stream

      expect(response.body).not_to match(%r{/l/["'\s<]})
    end
  end
end

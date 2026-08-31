require "rails_helper"

RSpec.describe "Redirects", type: :request do
  describe "GET /l/:short_code" do
    let!(:link) { create(:link, url: "https://example.com/destination") }

    it "redirects to the destination URL" do
      get "/l/#{link.short_code}"

      expect(response).to have_http_status(:found)
      expect(response).to redirect_to("https://example.com/destination")
    end

    it "records exactly one click" do
      expect { get "/l/#{link.short_code}" }.to change(ClickEvent, :count).by(1)
    end

    it "increments the link's counter cache" do
      get "/l/#{link.short_code}"

      expect(link.reload.click_events_count).to eq(1)
    end

    it "returns 404 for an unknown short code" do
      get "/l/doesnotexist"

      expect(response).to have_http_status(:not_found)
      expect(response.body).to include("Link not found")
    end

    it "records nothing for an unknown short code" do
      expect { get "/l/doesnotexist" }.not_to change(ClickEvent, :count)
    end
  end
end

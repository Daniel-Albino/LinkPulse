# =============================================================================
# spec/requests/health_spec.rb
# Testa o endpoint de health check.
# =============================================================================

require "rails_helper"

RSpec.describe "Health Check", type: :request do
  describe "GET /health" do
    context "when services are available" do
      before do
        allow(ActiveRecord::Base.connection).to receive(:execute).and_return(true)
        redis_double = instance_double(Redis, ping: "PONG")
        allow(Redis).to receive(:new).and_return(redis_double)
      end

      it "retorna HTTP 200" do
        get "/health"
        expect(response).to have_http_status(:ok)
      end

      it "retorna status ok em JSON" do
        get "/health"
        body = JSON.parse(response.body, symbolize_names: true)
        expect(body[:status]).to eq("ok")
      end

      it "inclui checks de database e redis" do
        get "/health"
        body = JSON.parse(response.body, symbolize_names: true)
        expect(body[:checks]).to include(:database, :redis)
      end
    end
  end
end

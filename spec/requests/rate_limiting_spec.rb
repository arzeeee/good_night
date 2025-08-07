require 'rails_helper'

RSpec.describe "Rate Limiting", type: :request do
  let!(:user) { create(:user, name: "testuser123") }

  before do
    Rack::Attack.cache.store.clear
  end

  describe "API rate limiting" do
    context "when making requests within rate limit" do
      it "allows requests under the limit" do
        4.times do
          post "/api/clock_in", params: { user: user.name }
          expect(response.status).to be < 400
        end
      end
    end

    context "when exceeding rate limit by IP" do
      it "returns 429 status when rate limit exceeded" do
        5.times do
          post "/api/clock_in", params: { user: user.name }
        end

        post "/api/clock_in", params: { user: user.name }
        
        expect(response).to have_http_status(:too_many_requests)
        json = JSON.parse(response.body)
        expect(json["error"]).to eq("Rate limit exceeded")
        expect(json["message"]).to include("Too many requests")
        expect(response.headers["Retry-After"]).to be_present
      end

      it "includes proper headers in rate limited response" do
        # Exceed the rate limit
        6.times do
          post "/api/clock_in", params: { user: user.name }
        end

        expect(response.headers["Content-Type"]).to include("application/json")
        expect(response.headers["Retry-After"]).to be_present
      end
    end

    context "different API endpoints" do
      it "rate limits across all API endpoints" do
        post "/api/clock_in", params: { user: user.name }
        post "/api/clock_out", params: { user: user.name }
        get "/api/user_clock_ins", params: { user: user.name }
        post "/api/clock_in", params: { user: user.name }
        post "/api/clock_out", params: { user: user.name }

        get "/api/user_clock_ins", params: { user: user.name }
        expect(response).to have_http_status(:too_many_requests)
      end
    end
  end

  describe "Non-API requests" do
    it "does not rate limit non-API requests" do
      10.times do
        get "/up"
        expect(response.status).to be < 400
      end
    end
  end
end

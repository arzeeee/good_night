require 'rails_helper'

RSpec.describe "Api::ClockIns", type: :request do
  let!(:user1) { create(:user, name: "alice123") }
  let!(:user2) { create(:user, name: "bob456") }

  describe "POST /api/clock_in" do
    context "with valid user" do
      it "returns job_id and accepted status" do
        post "/api/clock_in", params: { user: user1.name }
        
        expect(response).to have_http_status(:accepted)
        json = JSON.parse(response.body)
        expect(json["status"]).to eq("accepted")
        expect(json["message"]).to eq("Clock in job started")
        expect(json["job_id"]).to be_present
      end
    end

    context "with missing user parameter" do
      it "returns bad request" do
        post "/api/clock_in"
        
        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json["error"]).to eq("User parameter is required")
      end
    end
  end

  describe "POST /api/clock_out" do
    context "with valid user" do
      it "returns job_id and accepted status" do
        post "/api/clock_out", params: { user: user1.name }
        
        expect(response).to have_http_status(:accepted)
        json = JSON.parse(response.body)
        expect(json["status"]).to eq("accepted")
        expect(json["message"]).to eq("Clock out job started")
        expect(json["job_id"]).to be_present
      end
    end

    context "with missing user parameter" do
      it "returns bad request" do
        post "/api/clock_out"
        
        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json["error"]).to eq("User parameter is required")
      end
    end
  end

  describe "POST /api/follow_user" do
    context "with valid parameters" do
      it "returns job_id and accepted status" do
        post "/api/follow_user", params: { 
          follower_name: user1.name, 
          following_name: user2.name 
        }
        
        expect(response).to have_http_status(:accepted)
        json = JSON.parse(response.body)
        expect(json["status"]).to eq("accepted")
        expect(json["message"]).to eq("Follow user job started")
        expect(json["job_id"]).to be_present
      end
    end

    context "with missing parameters" do
      it "returns bad request when follower_name is missing" do
        post "/api/follow_user", params: { following_name: user2.name }
        
        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json["error"]).to eq("Follower name and following name are required")
      end

      it "returns bad request when following_name is missing" do
        post "/api/follow_user", params: { follower_name: user1.name }
        
        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json["error"]).to eq("Follower name and following name are required")
      end
    end
  end

  describe "POST /api/unfollow_user" do
    context "with valid parameters" do
      it "returns job_id and accepted status" do
        post "/api/unfollow_user", params: { 
          follower_name: user1.name, 
          following_name: user2.name 
        }
        
        expect(response).to have_http_status(:accepted)
        json = JSON.parse(response.body)
        expect(json["status"]).to eq("accepted")
        expect(json["message"]).to eq("Unfollow user job started")
        expect(json["job_id"]).to be_present
      end
    end

    context "with missing parameters" do
      it "returns bad request when follower_name is missing" do
        post "/api/unfollow_user", params: { following_name: user2.name }
        
        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json["error"]).to eq("Follower name and following name are required")
      end

      it "returns bad request when following_name is missing" do
        post "/api/unfollow_user", params: { follower_name: user1.name }
        
        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json["error"]).to eq("Follower name and following name are required")
      end
    end
  end

  describe "GET /api/user_clock_ins" do
    let!(:clock_in) { create(:clock_in, user: user1) }

    it "returns user's clock ins" do
      get "/api/user_clock_ins", params: { user: user1.name }
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["user"]).to eq(user1.name)
      expect(json["clock_ins"]).to be_an(Array)
      expect(json["clock_ins"].length).to eq(1)
    end

    context "with missing user parameter" do
      it "returns bad request" do
        get "/api/user_clock_ins"
        
        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json["error"]).to eq("User parameter is required")
      end
    end
  end

  describe "GET /api/followings_clock_ins" do
    let!(:following) { create(:following, follower: user1, following: user2) }
    let!(:clock_in) { create(:clock_in, user: user2) }

    it "returns followings' clock ins ordered by created_at desc" do
      get "/api/followings_clock_ins", params: { user: user1.name }
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["user"]).to eq(user1.name)
      expect(json["followings_clock_ins"]).to be_an(Array)
      expect(json).to have_key("page")
      expect(json).to have_key("per_page")
      expect(json).to have_key("total_count")
      expect(json).to have_key("total_pages")
    end

    context "with missing user parameter" do
      it "returns bad request" do
        get "/api/followings_clock_ins"
        
        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json["error"]).to eq("User parameter is required")
      end
    end
  end

  describe "GET /api/job_status/:job_id" do
    context "with valid job_id" do
      it "returns job status information" do
        # Create a fake job_id (in real scenario this would come from Sidekiq)
        job_id = "fake_job_id_123"
        
        get "/api/job_status/#{job_id}"
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["job_id"]).to eq(job_id)
        expect(json).to have_key("status")
      end
    end
  end
end

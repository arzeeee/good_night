require 'rails_helper'

RSpec.describe Api::ClockInsController, type: :controller do
  let(:user) { create(:user, name: "john123") }
  let(:other_user) { create(:user, name: "alice456") }

  describe "POST #clock_in" do
    context "with valid user name" do
      it "creates a new user if user doesn't exist" do
        expect {
          post :clock_in, params: { user: "newuser123" }
        }.to change(User, :count).by(1)
        
        expect(response).to have_http_status(:created)
        json_response = JSON.parse(response.body)
        expect(json_response['message']).to eq("Successfully clocked in")
        expect(json_response['user']).to eq("newuser123")
      end

      it "clocks in existing user successfully" do
        expect {
          post :clock_in, params: { user: user.name }
        }.to change(ClockIn, :count).by(1)
        
        expect(response).to have_http_status(:created)
        json_response = JSON.parse(response.body)
        expect(json_response['message']).to eq("Successfully clocked in")
        expect(json_response['user']).to eq(user.name)
        expect(json_response['clock_in_time']).to be_present
      end

      it "returns error if user is already clocked in" do
        create(:clock_in, user: user, clock_in_time: 1.hour.ago)
        
        expect {
          post :clock_in, params: { user: user.name }
        }.not_to change(ClockIn, :count)
        
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['message']).to eq("User already clocked in")
      end
    end
  end

  describe "POST #clock_out" do
    context "with valid user name" do
      it "creates a new user and returns already clocked out if user doesn't exist" do
        expect {
          post :clock_out, params: { user: "newuser123" }
        }.to change(User, :count).by(1)
        
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['message']).to eq("User already clocked out")
      end

      it "clocks out user successfully when clocked in" do
        clock_in = create(:clock_in, user: user, clock_in_time: 2.hours.ago)
        
        post :clock_out, params: { user: user.name }
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['message']).to eq("Successfully clocked out")
        expect(json_response['user']).to eq(user.name)
        expect(json_response['clock_out_time']).to be_present
        expect(json_response['duration_seconds']).to be_present
        
        clock_in.reload
        expect(clock_in.clock_out_time).to be_present
      end

      it "returns error if user is already clocked out" do
        create(:clock_in, :with_clock_out, user: user)
        
        post :clock_out, params: { user: user.name }
        
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['message']).to eq("User already clocked out")
      end
    end
  end

  describe "GET #user_clock_ins" do
    let!(:old_clock_in) { create(:clock_in, :with_clock_out, user: user, created_at: 2.weeks.ago) }
    let!(:recent_clock_in1) { create(:clock_in, :with_clock_out, user: user, created_at: 3.days.ago) }
    let!(:recent_clock_in2) { create(:clock_in, user: user, created_at: 1.day.ago) }

    it "creates a new user if user doesn't exist and returns empty clock_ins" do
      expect {
        get :user_clock_ins, params: { user: "newuser123" }
      }.to change(User, :count).by(1)
      
      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response['message']).to eq("User has no clock in time")
      expect(json_response['user']).to eq("newuser123")
      expect(json_response['clock_ins']).to be_empty
    end

    it "returns user's clock_ins from last week only" do
      get :user_clock_ins, params: { user: user.name }
      
      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response['user']).to eq(user.name)
      expect(json_response['clock_ins'].length).to eq(2)
      
      # Should not include old_clock_in (older than 1 week)
      clock_in_times = json_response['clock_ins'].map { |ci| ci['clock_in_time'] }
      expect(clock_in_times).not_to include(old_clock_in.clock_in_time.as_json)
    end

    it "shows 0 duration for ongoing sessions (not clocked out)" do
      get :user_clock_ins, params: { user: user.name }
      
      json_response = JSON.parse(response.body)
      ongoing_session = json_response['clock_ins'].find { |ci| ci['clock_out_time'].nil? }
      expect(ongoing_session['duration_seconds']).to eq(0)
    end

    it "shows actual duration for completed sessions" do
      get :user_clock_ins, params: { user: user.name }
      
      json_response = JSON.parse(response.body)
      completed_session = json_response['clock_ins'].find { |ci| ci['clock_out_time'].present? }
      expect(completed_session['duration_seconds'].to_f).to be > 0
    end
  end

  describe "POST #follow_user" do
    context "when both users exist" do
      it "creates following relationship successfully" do
        expect {
          post :follow_user, params: { follower_name: user.name, following_name: other_user.name }
        }.to change(Following, :count).by(1)
        
        expect(response).to have_http_status(:created)
        json_response = JSON.parse(response.body)
        expect(json_response['message']).to eq("#{user.name} is now following #{other_user.name}")
      end

      it "returns error if already following" do
        user.follow(other_user)
        
        expect {
          post :follow_user, params: { follower_name: user.name, following_name: other_user.name }
        }.not_to change(Following, :count)
        
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['message']).to eq("#{user.name} is already following #{other_user.name}")
      end
    end

    context "when following user doesn't exist" do
      it "returns error message" do
        post :follow_user, params: { follower_name: user.name, following_name: "nonexistent" }
        
        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response['message']).to eq("nonexistent does not exist")
      end

      it "creates follower if they don't exist" do
        expect {
          post :follow_user, params: { follower_name: "newuser", following_name: "nonexistent" }
        }.to change(User, :count).by(1)
        
        expect(User.find_by(name: "newuser")).to be_present
      end
    end
  end

  describe "POST #unfollow_user" do
    context "when both users exist and follower is following" do
      before do
        user.follow(other_user)
      end

      it "unfollows user successfully" do
        expect {
          post :unfollow_user, params: { follower_name: user.name, following_name: other_user.name }
        }.to change(Following, :count).by(-1)
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['message']).to eq("#{user.name} has unfollowed #{other_user.name}")
      end
    end

    context "when follower is not following the user" do
      it "returns error message" do
        post :unfollow_user, params: { follower_name: user.name, following_name: other_user.name }
        
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['message']).to eq("#{user.name} is not following #{other_user.name}")
      end
    end

    context "when following user doesn't exist" do
      it "returns error message" do
        post :unfollow_user, params: { follower_name: user.name, following_name: "nonexistent" }
        
        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response['message']).to eq("nonexistent does not exist")
      end

      it "creates follower if they don't exist" do
        expect {
          post :unfollow_user, params: { follower_name: "newuser", following_name: "nonexistent" }
        }.to change(User, :count).by(1)
        
        expect(User.find_by(name: "newuser")).to be_present
      end
    end
  end

  describe "GET #followings_clock_ins" do
    let(:follower) { create(:user, name: "follower") }
    let(:following1) { create(:user, name: "following1") }
    let(:following2) { create(:user, name: "following2") }
    
    before do
      follower.follow(following1)
      follower.follow(following2)
      
      # Create clock_ins for followed users
      create(:clock_in, :with_clock_out, user: following1, created_at: 2.days.ago, clock_in_time: 2.days.ago, clock_out_time: 2.days.ago + 2.hours)
      create(:clock_in, :with_clock_out, user: following2, created_at: 1.day.ago, clock_in_time: 1.day.ago, clock_out_time: 1.day.ago + 4.hours)
      
      # Create old clock_in (should not appear)
      create(:clock_in, :with_clock_out, user: following1, created_at: 2.weeks.ago)
      
      # Create ongoing clock_in (should not appear)
      create(:clock_in, user: following1, created_at: 1.day.ago)
    end

    it "returns paginated followings clock_ins sorted by duration" do
      get :followings_clock_ins, params: { user: follower.name, page: 1, per_page: 10 }
      
      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      
      expect(json_response['user']).to eq(follower.name)
      expect(json_response['page']).to eq(1)
      expect(json_response['per_page']).to eq(10)
      expect(json_response['followings_clock_ins'].length).to eq(2)
      
      # Should be sorted by duration (longest first)
      durations = json_response['followings_clock_ins'].map { |ci| ci['duration_seconds'].to_f }
      expect(durations).to eq(durations.sort.reverse)
    end

    it "only includes completed clock_ins from last week" do
      get :followings_clock_ins, params: { user: follower.name }
      
      json_response = JSON.parse(response.body)
      
      # Should only have 2 completed clock_ins, not the old one or ongoing one
      expect(json_response['followings_clock_ins'].length).to eq(2)
      
      # All should have clock_out_time
      json_response['followings_clock_ins'].each do |clock_in|
        expect(clock_in['clock_out_time']).to be_present
        expect(clock_in['duration_seconds'].to_f).to be > 0
      end
    end

    it "creates user if they don't exist" do
      expect {
        get :followings_clock_ins, params: { user: "newuser" }
      }.to change(User, :count).by(1)
      
      json_response = JSON.parse(response.body)
      expect(json_response['user']).to eq("newuser")
      expect(json_response['followings_clock_ins']).to be_empty
    end

    it "handles pagination correctly" do
      get :followings_clock_ins, params: { user: follower.name, page: 1, per_page: 1 }
      
      json_response = JSON.parse(response.body)
      expect(json_response['followings_clock_ins'].length).to eq(1)
      expect(json_response['total_count']).to eq(2)
      expect(json_response['total_pages']).to eq(2)
    end
  end
end

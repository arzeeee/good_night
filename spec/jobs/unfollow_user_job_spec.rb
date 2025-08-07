require 'rails_helper'

RSpec.describe UnfollowUserJob, type: :job do
  let!(:follower) { create(:user, name: "alice123") }
  let!(:following) { create(:user, name: "bob456") }

  describe "#perform" do
    context "when currently following" do
      let!(:follow_relation) { create(:following, follower: follower, following: following) }

      it "removes the following relationship" do
        expect {
          UnfollowUserJob.new.perform(follower.name, following.name)
        }.to change(Following, :count).by(-1)
        
        expect(Following.exists?(follower: follower, following: following)).to be false
      end

      it "returns success result" do
        result = UnfollowUserJob.new.perform(follower.name, following.name)
        
        expect(result[:success]).to be true
        expect(result[:message]).to eq("alice123 has unfollowed bob456")
      end
    end

    context "when not currently following" do
      it "returns error result" do
        result = UnfollowUserJob.new.perform(follower.name, following.name)
        
        expect(result[:success]).to be false
        expect(result[:error]).to eq("alice123 is not following bob456")
      end
    end

    context "with invalid follower name" do
      it "returns error result" do
        result = UnfollowUserJob.new.perform("nonexistent", following.name)
        
        expect(result[:success]).to be false
        expect(result[:error]).to eq("Follower nonexistent not found")
      end
    end

    context "with invalid following name" do
      it "returns error result" do
        result = UnfollowUserJob.new.perform(follower.name, "nonexistent")
        
        expect(result[:success]).to be false
        expect(result[:error]).to eq("Following user nonexistent not found")
      end
    end
  end
end

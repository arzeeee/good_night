require 'rails_helper'

RSpec.describe FollowUserJob, type: :job do
  let!(:follower) { create(:user, name: "alice123") }
  let!(:following) { create(:user, name: "bob456") }

  describe "#perform" do
    context "with valid users" do
      it "creates a following relationship" do
        expect {
          FollowUserJob.new.perform(follower.name, following.name)
        }.to change(Following, :count).by(1)
        
        follow_relation = Following.last
        expect(follow_relation.follower).to eq(follower)
        expect(follow_relation.following).to eq(following)
      end

      it "returns success result" do
        result = FollowUserJob.new.perform(follower.name, following.name)
        
        expect(result[:success]).to be true
        expect(result[:message]).to eq("alice123 is now following bob456")
      end
    end

    context "when already following" do
      before do
        create(:following, follower: follower, following: following)
      end

      it "returns error result" do
        result = FollowUserJob.new.perform(follower.name, following.name)
        
        expect(result[:success]).to be false
        expect(result[:error]).to eq("alice123 is already following bob456")
      end

      it "does not create additional following record" do
        expect {
          FollowUserJob.new.perform(follower.name, following.name)
        }.not_to change(Following, :count)
      end
    end

    context "when trying to follow self" do
      it "returns error result" do
        result = FollowUserJob.new.perform(follower.name, follower.name)
        
        expect(result[:success]).to be false
        expect(result[:error]).to eq("User cannot follow themselves")
      end
    end

    context "with invalid follower name" do
      it "returns error result" do
        result = FollowUserJob.new.perform("nonexistent", following.name)
        
        expect(result[:success]).to be false
        expect(result[:error]).to eq("Follower nonexistent not found")
      end
    end

    context "with invalid following name" do
      it "returns error result" do
        result = FollowUserJob.new.perform(follower.name, "nonexistent")
        
        expect(result[:success]).to be false
        expect(result[:error]).to eq("Following user nonexistent not found")
      end
    end
  end
end

require 'rails_helper'

RSpec.describe ClockOutJob, type: :job do
  let!(:user) { create(:user, name: "alice123") }

  describe "#perform" do
    context "with user currently clocked in" do
      let!(:clock_in) { create(:clock_in, user: user, clock_out_time: nil) }

      it "updates the clock in record with clock out time" do
        ClockOutJob.new.perform(user.name)
        
        clock_in.reload
        expect(clock_in.clock_out_time).to be_present
        expect(clock_in.duration).to be > 0
      end

      it "returns success result" do
        result = ClockOutJob.new.perform(user.name)
        
        expect(result[:success]).to be true
        expect(result[:message]).to eq("Successfully clocked out alice123")
        expect(result[:clock_in_id]).to eq(clock_in.id)
      end
    end

    context "with user not currently clocked in" do
      it "returns error result" do
        result = ClockOutJob.new.perform(user.name)
        
        expect(result[:success]).to be false
        expect(result[:error]).to eq("User alice123 is not currently clocked in")
      end
    end

    context "with invalid user name" do
      it "returns error result" do
        result = ClockOutJob.new.perform("nonexistent")
        
        expect(result[:success]).to be false
        expect(result[:error]).to eq("User nonexistent not found")
      end
    end
  end
end

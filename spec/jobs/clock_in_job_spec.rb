require 'rails_helper'

RSpec.describe ClockInJob, type: :job do
  let!(:user) { create(:user, name: "alice123") }

  describe "#perform" do
    context "with valid user name" do
      it "creates a clock in record" do
        expect {
          ClockInJob.new.perform(user.name)
        }.to change(ClockIn, :count).by(1)
        
        clock_in = ClockIn.last
        expect(clock_in.user).to eq(user)
        expect(clock_in.clock_out_time).to be_nil
      end

      it "returns success result" do
        result = ClockInJob.new.perform(user.name)
        
        expect(result[:success]).to be true
        expect(result[:message]).to eq("Successfully clocked in alice123")
        expect(result[:clock_in_id]).to be_present
      end
    end

    context "with user already clocked in" do
      before do
        create(:clock_in, user: user, clock_out_time: nil)
      end

      it "returns error result" do
        result = ClockInJob.new.perform(user.name)
        
        expect(result[:success]).to be false
        expect(result[:error]).to eq("User alice123 is already clocked in")
      end

      it "does not create additional clock in record" do
        expect {
          ClockInJob.new.perform(user.name)
        }.not_to change(ClockIn, :count)
      end
    end

    context "with invalid user name" do
      it "returns error result" do
        result = ClockInJob.new.perform("nonexistent")
        
        expect(result[:success]).to be false
        expect(result[:error]).to eq("User nonexistent not found")
      end
    end
  end
end

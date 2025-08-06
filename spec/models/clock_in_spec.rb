require 'rails_helper'

RSpec.describe ClockIn, type: :model do
  let(:user) { create(:user, name: "john123") }
  let(:clock_in_time) { 2.hours.ago }
  let(:clock_out_time) { 1.hour.ago }

  describe 'associations' do
    it 'belongs to user' do
      association = described_class.reflect_on_association(:user)
      expect(association.macro).to eq :belongs_to
    end
  end

  describe 'validations' do
    context 'with valid attributes' do
      it 'is valid with user and clock_in_time' do
        clock_in = ClockIn.new(user: user, clock_in_time: clock_in_time)
        expect(clock_in).to be_valid
      end

      it 'is valid with user, clock_in_time, and clock_out_time' do
        clock_in = ClockIn.new(user: user, clock_in_time: clock_in_time, clock_out_time: clock_out_time)
        expect(clock_in).to be_valid
      end
    end

    context 'presence validations' do
      it 'requires clock_in_time' do
        clock_in = ClockIn.new(user: user)
        expect(clock_in).not_to be_valid
        expect(clock_in.errors[:clock_in_time]).to include("can't be blank")
      end

      it 'requires user' do
        clock_in = ClockIn.new(clock_in_time: clock_in_time)
        expect(clock_in).not_to be_valid
        expect(clock_in.errors[:user]).to include("must exist")
      end
    end

    context 'duration_seconds validation' do
      it 'allows positive duration_seconds' do
        clock_in = ClockIn.new(user: user, clock_in_time: clock_in_time, duration_seconds: 3600)
        expect(clock_in).to be_valid
      end

      it 'allows zero duration_seconds' do
        clock_in = ClockIn.new(user: user, clock_in_time: clock_in_time, duration_seconds: 0)
        expect(clock_in).to be_valid
      end

      it 'does not allow negative duration_seconds' do
        clock_in = ClockIn.new(user: user, clock_in_time: clock_in_time, duration_seconds: -100)
        expect(clock_in).not_to be_valid
        expect(clock_in.errors[:duration_seconds]).to include("must be greater than or equal to 0")
      end

      it 'allows nil duration_seconds' do
        clock_in = ClockIn.new(user: user, clock_in_time: clock_in_time, duration_seconds: nil)
        expect(clock_in).to be_valid
      end
    end
  end

  describe '#clocked_out?' do
    context 'when clock_out_time is present' do
      it 'returns true' do
        clock_in = build(:clock_in, :with_clock_out)
        expect(clock_in.clocked_out?).to be true
      end
    end

    context 'when clock_out_time is nil' do
      it 'returns false' do
        clock_in = build(:clock_in)
        expect(clock_in.clocked_out?).to be false
      end
    end

    context 'when clock_out_time is blank' do
      it 'returns false' do
        clock_in = build(:clock_in, clock_out_time: '')
        expect(clock_in.clocked_out?).to be false
      end
    end
  end

  describe '#duration' do
    context 'when clocked out' do
      it 'returns the time difference between clock_in_time and clock_out_time' do
        clock_in = build(:clock_in, clock_in_time: clock_in_time, clock_out_time: clock_out_time)
        expected_duration = clock_out_time - clock_in_time
        expect(clock_in.duration).to be_within(0.001).of(expected_duration)
      end

      it 'calculates duration correctly for different time spans' do
        start_time = Time.current
        end_time = start_time + 2.hours + 30.minutes
        clock_in = build(:clock_in, clock_in_time: start_time, clock_out_time: end_time)
        
        expect(clock_in.duration).to eq(2.hours + 30.minutes)
      end
    end

    context 'when not clocked out' do
      it 'returns nil' do
        clock_in = build(:clock_in, clock_out_time: nil)
        expect(clock_in.duration).to be_nil
      end
    end
  end

  describe 'after_save callback: calculate_duration_seconds' do
    context 'when clock_out_time is present' do
      it 'automatically calculates and saves duration_seconds' do
        clock_in = create(:clock_in, clock_in_time: clock_in_time, clock_out_time: clock_out_time)
        expected_duration = clock_out_time - clock_in_time
        
        clock_in.reload
        expect(clock_in.duration_seconds).to be_within(0.001).of(expected_duration)
      end

      it 'updates duration_seconds when clock_out_time is added later' do
        clock_in = create(:clock_in, clock_in_time: clock_in_time)
        expect(clock_in.duration_seconds).to be_nil
        
        clock_in.update!(clock_out_time: clock_out_time)
        expected_duration = clock_out_time - clock_in_time
        
        clock_in.reload
        expect(clock_in.duration_seconds).to be_within(0.001).of(expected_duration)
      end
    end

    context 'when clock_out_time is not present' do
      it 'does not set duration_seconds' do
        clock_in = create(:clock_in, clock_in_time: clock_in_time)
        expect(clock_in.duration_seconds).to be_nil
      end
    end
  end

  describe 'factory traits' do
    context 'with_clock_out trait' do
      it 'creates a clock_in with clock_out_time' do
        clock_in = build(:clock_in, :with_clock_out)
        expect(clock_in.clock_out_time).to be_present
        expect(clock_in.clocked_out?).to be true
      end
    end

    context 'long_duration trait' do
      it 'creates a clock_in with a long duration' do
        clock_in = build(:clock_in, :long_duration)
        expect(clock_in.duration).to be > 6.hours
      end
    end

    context 'short_duration trait' do
      it 'creates a clock_in with a short duration' do
        clock_in = build(:clock_in, :short_duration)
        expect(clock_in.duration).to be < 1.hour
      end
    end
  end

  describe 'user association' do
    it 'is destroyed when user is destroyed' do
      clock_in = create(:clock_in, user: user)
      
      expect {
        user.destroy
      }.to change(ClockIn, :count).by(-1)
    end

    it 'allows multiple clock_ins for the same user' do
      clock_in1 = create(:clock_in, user: user, clock_in_time: 2.hours.ago)
      clock_in2 = create(:clock_in, user: user, clock_in_time: 1.hour.ago)
      
      expect(user.clock_ins).to include(clock_in1, clock_in2)
      expect(user.clock_ins.count).to eq(2)
    end
  end

  describe 'edge cases' do
    it 'handles very short durations correctly' do
      start_time = Time.current
      end_time = start_time + 1.second
      clock_in = create(:clock_in, clock_in_time: start_time, clock_out_time: end_time)
      
      expect(clock_in.duration).to eq(1.second)
      expect(clock_in.duration_seconds).to eq(1.0)
    end

    it 'handles same clock_in_time and clock_out_time' do
      same_time = Time.current
      clock_in = create(:clock_in, clock_in_time: same_time, clock_out_time: same_time)
      
      expect(clock_in.duration).to eq(0)
      expect(clock_in.duration_seconds).to eq(0.0)
    end
  end
end

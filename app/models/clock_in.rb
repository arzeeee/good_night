class ClockIn < ApplicationRecord
  belongs_to :user

  validates :clock_in_time, presence: true
  validates :duration_seconds, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  after_save :calculate_duration_seconds

  def clocked_out?
    clock_out_time.present?
  end

  def duration
    return nil unless clocked_out?

    clock_out_time - clock_in_time
  end

  private

  def calculate_duration_seconds
    if clock_out_time.present?
      update_column(:duration_seconds, duration)
    end
  end
end

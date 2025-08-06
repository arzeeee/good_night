FactoryBot.define do
  factory :clock_in do
    association :user
    clock_in_time { 1.hour.ago }

    trait :with_clock_out do
      clock_out_time { 30.minutes.ago }
    end

    trait :long_duration do
      clock_in_time { 8.hours.ago }
      clock_out_time { 1.hour.ago }
    end

    trait :short_duration do
      clock_in_time { 15.minutes.ago }
      clock_out_time { 5.minutes.ago }
    end
  end
end

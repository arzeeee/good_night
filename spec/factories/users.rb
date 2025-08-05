FactoryBot.define do
  factory :user do
    name { "JohnDoe" }

    trait :with_letters_only do
      name { "john" }
    end

    trait :with_numbers_only do
      name { "123456" }
    end

    trait :with_mixed_alphanumeric do
      name { "JaneDoe123" }
    end
  end
end

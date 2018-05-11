FactoryBot.define do
  factory :activity_type do
    activity_category
    sequence(:name) {|n| "test activity_type name #{n}"}
    score 25
    active true
    data_driven true
    repeatable true
    description 'test_activity_type description'

    trait :as_initial_suggestions do
      after(:create) do |activity_type, evaluator|
        create :activity_type_suggestion, suggested_type: activity_type
      end
    end

    trait :with_further_suggestions do
      transient do
        number_of_suggestions 1
        key_stages { [ActsAsTaggableOn::Tag.where(name: 'KS1').first_or_create] }
      end

      after(:create) do |original_activity_type, evaluator|
        evaluator.number_of_suggestions.times do |index|
          follow_on_activity_type = create :activity_type, key_stages: evaluator.key_stages, score: 33
          create :activity_type_suggestion, activity_type: original_activity_type, suggested_type: follow_on_activity_type
        end
      end
    end
  end
end

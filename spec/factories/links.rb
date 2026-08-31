FactoryBot.define do
  factory :link do
    # A sequence keeps the uniqueness validation on :url happy when an example
    # builds more than one link. short_code is not set here: the model
    # generates it in a before_create callback.
    sequence(:url) { |n| "https://example.com/page-#{n}" }
  end
end

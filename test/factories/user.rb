FactoryBot.define do
  factory :user do
    uuid { SecureRandom.uuid }
  end
end
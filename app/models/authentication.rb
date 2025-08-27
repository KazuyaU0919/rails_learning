# app/models/authentication.rb
class Authentication < ApplicationRecord
  belongs_to :user

  PROVIDERS = %w[google_oauth2 github].freeze

  validates :provider, :uid, presence: true
  validates :uid, uniqueness:   { scope: :provider }
  validates :provider, inclusion: { in: PROVIDERS }
  validates :provider, uniqueness: { scope: :user_id }

  # 便利スコープ
  scope :for_provider,    ->(provider) { where(provider: provider) }
  scope :google_oauth2,   -> { where(provider: "google_oauth2") }
  scope :github,          -> { where(provider: "github") }
end

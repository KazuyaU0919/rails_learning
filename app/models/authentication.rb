# ============================================================
# Authentication
# ------------------------------------------------------------
# 外部認証（Google / GitHub など）の連携情報を保持するモデル。
# 1ユーザーに対してプロバイダ×UIDのペアで一意。
# ============================================================

class Authentication < ApplicationRecord
  # =======================
  # 関連
  # =======================
  belongs_to :user

  # =======================
  # 定数
  # =======================
  PROVIDERS = %w[google_oauth2 github].freeze

  # =======================
  # バリデーション
  # =======================
  validates :provider, :uid, presence: true
  validates :uid, uniqueness:   { scope: :provider }       # 同一provider内でUID一意
  validates :provider, inclusion: { in: PROVIDERS }        # 許可プロバイダのみ
  validates :provider, uniqueness: { scope: :user_id }     # 同一ユーザに同一providerは1つ

  # =======================
  # スコープ
  # =======================
  scope :for_provider,  ->(provider) { where(provider: provider) }
  scope :google_oauth2, -> { where(provider: "google_oauth2") }
  scope :github,        -> { where(provider: "github") }
end

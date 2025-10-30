# ============================================================
# UsedCode
# ------------------------------------------------------------
# ユーザーが PreCode を「使用した」履歴を保持するモデル。
# counter_cache により PreCode#use_count を自動更新。
# ============================================================

class UsedCode < ApplicationRecord
  # =======================
  # 関連
  # =======================
  belongs_to :user
  belongs_to :pre_code, counter_cache: :use_count

  # =======================
  # バリデーション
  # =======================
  validates :used_at, presence: true

  # =======================
  # コールバック
  # =======================
  before_validation :set_used_at, on: :create

  private

  # created時に used_at が空なら現在時刻を補完
  def set_used_at
    self.used_at ||= Time.current
  end
end

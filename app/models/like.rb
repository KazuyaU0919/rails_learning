# ============================================================
# Like
# ------------------------------------------------------------
# ユーザーが PreCode を「いいね」した情報を保持する中間モデル。
# counter_cache により PreCode#like_count を自動更新。
# ============================================================

class Like < ApplicationRecord
  # =======================
  # 関連
  # =======================
  belongs_to :user
  belongs_to :pre_code, counter_cache: :like_count

  # =======================
  # バリデーション
  # =======================
  validates :user_id, uniqueness: { scope: :pre_code_id }
end

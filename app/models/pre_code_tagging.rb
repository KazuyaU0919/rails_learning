# ============================================================
# PreCodeTagging
# ------------------------------------------------------------
# PreCode と Tag の多対多関係を表す中間モデル。
# 作成/削除時に Tag の zero_since を整合させる。
# ============================================================

class PreCodeTagging < ApplicationRecord
  # =======================
  # 関連
  # =======================
  belongs_to :pre_code
  belongs_to :tag, counter_cache: :taggings_count

  # =======================
  # バリデーション
  # =======================
  validates :pre_code_id, uniqueness: { scope: :tag_id }

  # =======================
  # コールバック
  # =======================
  # counter_cache 更新後に、未使用期間フラグを更新
  after_commit :refresh_tag_zero_since!, on: %i[create destroy]

  private

  def refresh_tag_zero_since!
    tag.reload
    tag.refresh_zero_since!
  end
end

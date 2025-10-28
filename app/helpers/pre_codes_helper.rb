# ============================================================
# Helper: PreCode 表示系
# ------------------------------------------------------------
# 目的:
# - PreCode に付随する自由入力 HTML を安全に表示する。
# - ビュー側では sanitize 設定を集中管理。
# ============================================================
module PreCodesHelper
  # 許可する HTML タグ & 属性（最小限）
  ALLOWED_TAGS  = %w[b i em strong code pre br p ul ol li a].freeze
  ALLOWED_ATTRS = %w[href].freeze

  # =======================
  # 安全な HTML 出力
  # -----------------------
  # sanitize(…) の許可リストに基づいてサニタイズした文字列を返す。
  # 例) <%= sanitized_html(@pre_code.description) %>
  # =======================
  def sanitized_html(html)
    sanitize(html, tags: ALLOWED_TAGS, attributes: ALLOWED_ATTRS)
  end
end

# ============================================================
# Service: RichTextSanitizer
# ------------------------------------------------------------
# HTMLコンテンツのサニタイズ（許可リスト方式）。
# 利用箇所:
# - 各Controllerの保存前サニタイズ
# - View表示の二重防御にも使用可
# ポリシー:
# - Quill等の基本表現（見出し、pre/code、リンク、画像等）を許可
# - それ以外はフラットに除去
# ============================================================
class RichTextSanitizer
  # 許可タグ（最小限の装飾要素 + コード + 画像 + 区切り線）
  ALLOWED_TAGS = %w[
    p pre code h1 h2 h3 h4 h5 h6 b i u strong em a ul ol li br blockquote span div img hr
  ].freeze

  # 許可属性（img表示に必要な属性を含む）
  ALLOWED_ATTRS = %w[href class rel target src alt loading width height style].freeze

  # =======================
  # エントリポイント
  # -----------------------
  # 引数: html (String or nil)
  # 戻り: サニタイズ済みHTML(String)
  # =======================
  def self.call(html)
    ActionController::Base.helpers.sanitize(
      html.to_s,
      tags: ALLOWED_TAGS,
      attributes: ALLOWED_ATTRS
    )
  end
end

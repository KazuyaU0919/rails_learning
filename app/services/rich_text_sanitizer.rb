# ============================================================
# Service: RichTextSanitizer
# ------------------------------------------------------------
# HTMLコンテンツのサニタイズ（許可リスト方式）。
#
# 目的:
# - Quill(+better-table) で生成される表を安全に通しつつ、
#   危険なタグ(<script>等)やイベント属性(onerror等)を確実に除去する。
# - 画像の簡易リサイズなど最低限の inline style はホワイトリストで許可。
#
# 利用箇所:
# - 各Controllerの保存前サニタイズ（必須）
# - View表示の二重防御（Helper経由で必要に応じて）
# ============================================================
class RichTextSanitizer
  # 許可タグ（Quill標準 + 表関連）
  ALLOWED_TAGS = %w[
    p br hr div span strong em b i u s blockquote pre code
    ul ol li
    a img
    h1 h2 h3 h4 h5 h6
    table thead tbody tfoot tr th td
  ].freeze

  # 許可属性（画像/リンク/表で最低限必要なもの）
  ALLOWED_ATTRS = %w[
    href rel target
    src alt title
    class id
    style
    rowspan colspan
    width height loading
  ].freeze

  # style のホワイトリスト（許すプロパティの組合せのみ）
  SAFE_STYLES = /\A(?:
    (?:text-align\s*:\s*(?:left|center|right|justify)\s*;?\s*)|
    (?:width\s*:\s*(?:\d{1,3}%|\d+(?:px)?)\s*;?\s*)|
    (?:height\s*:\s*(?:\d{1,3}%|\d+(?:px)?)\s*;?\s*)|
    (?:border(?:-[a-z\-]+)?\s*:\s*[^;]+;?\s*)|
    (?:background(?:-color)?\s*:\s*[^;]+;?\s*)|
    (?:padding\s*:\s*[^;]+;?\s*)|
    (?:margin\s*:\s*[^;]+;?\s*)
  )*\z/ix

  # Rails 標準のホワイトリストサニタイザを明示利用
  SANITIZER = Rails::Html::WhiteListSanitizer.new

  # =======================
  # エントリポイント
  # =======================
  def self.call(html)
    str = html.to_s

    # 1st-pass: まず許可タグ/属性だけに削る
    str = SANITIZER.sanitize(str, tags: ALLOWED_TAGS, attributes: ALLOWED_ATTRS)

    # 2nd-pass: Loofah で微調整（on* 属性除去 / style 制限 / a補完）
    frag = Loofah.fragment(str)
    frag.scrub!(Loofah::Scrubber.new do |node|
      # すべての on* イベント属性を削除（onerror, onclick, ...）
      node.attribute_nodes.each do |attr|
        node.remove_attribute(attr.name) if attr.name.to_s.downcase.start_with?("on")
      end

      # style の安全化（許可外は style ごと除去）
      if node["style"].present?
        node["style"] = node["style"].to_s.strip
        node.remove_attribute("style") unless node["style"].match?(SAFE_STYLES)
      end

      # a タグの安全な既定値
      if node.name == "a"
        node["rel"] = "noopener noreferrer" unless node["rel"].present?
        node["target"] = "_blank" if node["href"].present? && node["target"].blank?
      end
    end)

    frag.to_s
  end
end

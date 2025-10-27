# ============================================================
# Helper: パンくずリスト (JSON-LD 用)
# ------------------------------------------------------------
# 目的:
# - view で構築済みの `breadcrumbs` 配列（text/path を持つ）を
#   Schema.org の BreadcrumbList 形式(JSON-LD)に整形して返す。
# - SEO 支援: 検索クローラがパンくずを理解しやすくなる。
#
# 使い方:
#   <script type="application/ld+json"><%= breadcrumbs_json_ld %></script>
# ============================================================
module BreadcrumbsHelper
  # =======================
  # JSON-LD 生成
  # =======================
  def breadcrumbs_json_ld
    list = breadcrumbs.map.with_index(1) do |c, i|
      {
        "@type": "ListItem",
        position: i,               # 1-origin
        name: c.text.to_s,         # 表示テキスト
        item: (c.path ? url_for(c.path) : nil) # URL（あれば）
      }.compact
    end

    {
      "@context": "https://schema.org",
      "@type": "BreadcrumbList",
      itemListElement: list
    }.to_json
  end
end

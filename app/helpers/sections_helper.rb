# app/helpers/sections_helper.rb
module SectionsHelper
  # BookSection の本文を安全に表示（表示側の二重防御）
  # 必要なタグ/属性は用途に応じて調整
  def render_section_content(section)
    allowed_tags  = %w[
      p pre code h1 h2 h3 h4 h5 h6 b i u strong em a ul ol li br blockquote span div img
    ]
    # 画像表示に必要な属性を許可（最小限）
    allowed_attrs = %w[href class rel target src alt loading width height]

    sanitize(section.content.to_s, tags: allowed_tags, attributes: allowed_attrs)
  end
end

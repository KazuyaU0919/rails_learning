module SectionsHelper
  # BookSection の本文を安全に表示
  # 必要なタグ/属性は運用に合わせて調整
  def render_section_content(section)
    allowed_tags = %w[p pre code h1 h2 h3 h4 h5 h6 strong em a ul ol li br blockquote]
    allowed_attrs = %w[href class rel target]
    sanitize(section.content.to_s, tags: allowed_tags, attributes: allowed_attrs)
  end
end

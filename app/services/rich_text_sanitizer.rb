# app/services/rich_text_sanitizer.rb
# どこからでも呼べる共通サニタイザ（サービスオブジェクト）
class RichTextSanitizer
  ALLOWED_TAGS = %w[
    p pre code h1 h2 h3 h4 h5 h6 b i u strong em a ul ol li br blockquote span div img hr
  ].freeze

  # img の表示に最低限必要な属性＋基本属性
  ALLOWED_ATTRS = %w[href class rel target src alt loading width height style].freeze

  def self.call(html)
    ActionController::Base.helpers.sanitize(
      html.to_s,
      tags: ALLOWED_TAGS,
      attributes: ALLOWED_ATTRS
    )
  end
end

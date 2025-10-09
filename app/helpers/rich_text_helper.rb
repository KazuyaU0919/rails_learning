# app/helpers/rich_text_helper.rb
module RichTextHelper
  # ビューからはこれ一発でOK
  # 例: <%= rich_html(@question.explanation) %>
  def rich_html(html)
    RichTextSanitizer.call(html)
  end
end

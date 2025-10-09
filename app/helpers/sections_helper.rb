# app/helpers/sections_helper.rb
module SectionsHelper
  # BookSection の本文を安全に表示（表示側の二重防御）
  def render_section_content(section)
    RichTextSanitizer.call(section.content)
  end
end

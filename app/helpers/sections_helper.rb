# ============================================================
# Helper: BookSection 表示補助
# ------------------------------------------------------------
# 目的:
# - BookSection の本文 content を安全に表示（表示側の二重防御）
# - 保存時サニタイズに加えて、表示段でも RichTextSanitizer を適用
# ============================================================
module SectionsHelper
  # =======================
  # 本文の安全描画
  # -----------------------
  # 例) <%= render_section_content(@section) %>
  # =======================
  def render_section_content(section)
    RichTextSanitizer.call(section.content)
  end
end

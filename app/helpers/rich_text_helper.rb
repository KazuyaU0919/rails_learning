# ============================================================
# Helper: RichTextHelper
# ------------------------------------------------------------
# 目的:
#   - 保存済みの本文HTMLを「再サニタイズ」したうえで安全に描画する。
#   - .html_safe を直接使わず、必ず RichTextSanitizer を通した結果だけを可視化。
# 使い方:
#   <%= rich_html(@section.content) %>
# ============================================================
module RichTextHelper
  def rich_html(html)
    # もう一度ホワイトリスト方式でクリーンにしてから描画
    RichTextSanitizer.call(html).html_safe
  end
end

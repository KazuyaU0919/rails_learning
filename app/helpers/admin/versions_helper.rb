# app/helpers/admin/versions_helper.rb
module Admin::VersionsHelper
  # HTMLを人が読みやすいプレーンテキストへ
  # - <br>       => 改行
  # - </p> </li> => 改行（段落/箇条書きの区切り）
  # - <li>       => 先頭に中黒（・）
  # その後 strip_tags で安全にタグ除去
  def textify_html(html)
    s = html.to_s.dup
    s.gsub!(/<br\s*\/?>/i, "\n")
    s.gsub!(/<\/p\s*>/i, "\n\n")
    s.gsub!(/<\/li\s*>/i, "\n")
    s.gsub!(/<li[^>]*>/i, "・")
    s = strip_tags(s)
    s.gsub(/\n{3,}/, "\n\n").strip
  end

  # とりあえずの行単位の簡易差分
  # （厳密なLCSではないが軽量で、どこが増減したかは掴める）
  def simple_line_diff(before_html, after_html)
    before_lines = textify_html(before_html).split(/\r?\n/)
    after_lines  = textify_html(after_html).split(/\r?\n/)

    {
      added:   after_lines - before_lines,
      removed: before_lines - after_lines,
      before_lines:,
      after_lines:
    }
  end
end

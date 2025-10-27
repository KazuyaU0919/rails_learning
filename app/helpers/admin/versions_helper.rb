# ============================================================
# Helper: 管理 > Versions (PaperTrail)
# ------------------------------------------------------------
# 目的:
# - HTML差分や操作履歴を人が読める形式に整形
# - 操作ユーザーや編集ページへのリンクを補助
# ============================================================
module Admin::VersionsHelper

  # =======================
  # HTML → プレーンテキスト変換
  # -----------------------
  # Quill 等で生成されたHTMLを読みやすく整形。
  # コードブロックは ```code``` に変換。
  # =======================
  def textify_html(html)
    s = html.to_s.dup
    s.gsub!(/&nbsp;/i, " ")
    s.gsub!(%r{<style[^>]*>.*?</style>}mi, "")
    s.gsub!(%r{<script[^>]*>.*?</script>}mi, "")
    s.gsub!(/<br\s*\/?>/i, "\n")
    s.gsub!(/<\/p\s*>/i, "\n\n")
    s.gsub!(/<\/li\s*>/i, "\n")
    s.gsub!(/<li[^>]*>/i, "・")
    s.gsub!(/<pre[^>]*><code[^>]*>(.*?)<\/code><\/pre>/mi) { "\n```\n#{$1}\n```\n" }
    s = strip_tags(s)
    s.gsub(/\n{3,}/, "\n\n").strip
  end

  # =======================
  # 簡易的な行単位の差分
  # -----------------------
  # before/after をテキスト化して比較。
  # =======================
  def simple_line_diff(before_html, after_html)
    before_lines = textify_html(before_html).split(/\r?\n/)
    after_lines  = textify_html(after_html).split(/\r?\n/)
    { added: after_lines - before_lines, removed: before_lines - after_lines,
      before_lines:, after_lines: }
  end

  # =======================
  # 項目種別の表示ラベル
  # =======================
  def label_for_item_type(type)
    case type.to_s
    when "BookSection"  then "テキスト"
    when "QuizQuestion" then "クイズ"
    else type.to_s
    end
  end

  # =======================
  # カラム名 → 日本語ラベル
  # =======================
  def label_for_column(col)
    case col.to_s
    when "updated_at"      then "更新日時"
    when "lock_version"    then "ロックバージョン"
    when "content"         then "content（本文）"
    when "quiz_section_id" then "quiz_section_id（相互リンク）"
    when "question"        then "問題文"
    when "explanation"     then "解説"
    when "choice1"         then "選択肢1"
    when "choice2"         then "選択肢2"
    when "choice3"         then "選択肢3"
    when "choice4"         then "選択肢4"
    when "correct_choice"  then "正解(1..4)"
    else col.to_s
    end
  end

  # =======================
  # 操作者情報の取得
  # =======================
  def actor_for(version)
    uid = version.whodunnit.to_s
    return nil if uid.blank? || uid !~ /\A\d+\z/
    User.find_by(id: uid.to_i)
  end

  # 操作者のバッジ表示
  def actor_badge(version)
    if (u = actor_for(version))
      %(ID: #{u.id} / #{ERB::Util.h u.name} / #{ERB::Util.h u.email})
    else
      ERB::Util.h(version.whodunnit.presence || "-")
    end
  end

  # =======================
  # 編集ページへのリンクパス
  # -----------------------
  # 対象のレコードが存在する場合のみURLを返す。
  # =======================
  def admin_edit_path_for(version)
    id = version.item_id
    case version.item_type
    when "BookSection"
      Rails.application.routes.url_helpers.edit_admin_book_section_path(id)
    when "QuizQuestion"
      Rails.application.routes.url_helpers.edit_admin_quiz_question_path(id)
    else
      nil
    end
  rescue
    nil
  end
end

# ============================================================
# Mailer: AdminDigestMailer
# ------------------------------------------------------------
# 管理者向けダイジェスト通知メール。
# - edits_digest: 指定時間帯の更新履歴（PaperTrail）を通知
# - contact_digest: 問い合わせ件数の通知
# ポリシー：
#   * 送信先は ENV["ADMIN_EMAIL"] or 管理者ユーザー or MAIL_FROM にフォールバック
#   * 件名は対象ウィンドウの時刻を含めて判別しやすく
# ============================================================
class AdminDigestMailer < ApplicationMailer
  # =======================
  # 編集通知（更新履歴）
  # -----------------------
  # 引数:
  #   edits        : [{ at:, user:, item_type:, item_id:, title: }, ...]
  #   window_start : 開始時刻
  #   window_end   : 終了時刻
  # ビューでは @edits, @admin_names, @login_url などを使用
  # =======================
  def edits_digest(edits:, window_start:, window_end:)
    @edits        = edits
    @window_start = window_start
    @window_end   = window_end
    @login_url    = Rails.application.routes.url_helpers.new_session_url
    @admin_names  = admin_names

    mail(
      to: admin_recipients,
      subject: "編集内容の通知（#{l @window_start, format: :short} 〜 #{l @window_end, format: :short}）"
    )
  end

  # =======================
  # 問い合わせ通知
  # -----------------------
  # 引数:
  #   count        : 対象ウィンドウ内の問い合わせ数
  #   window_start : 開始時刻
  #   window_end   : 終了時刻
  # ビューでは @count, @form_url, @admin_names などを使用
  # =======================
  def contact_digest(count:, window_start:, window_end:)
    @count        = count
    @window_start = window_start
    @window_end   = window_end
    @form_url     = ENV["GOOGLE_FORM_CONFIRM_URL"].presence
    @admin_names  = admin_names

    mail(
      to: admin_recipients,
      subject: "Rails Learningにおいて、問い合わせがありました（#{l @window_start, format: :short} 〜 #{l @window_end, format: :short}）"
    )
  end

  private
  # =======================
  # 宛先の決定ロジック
  # -----------------------
  # 1) ENV["ADMIN_EMAIL"]（カンマ区切り）
  # 2) 管理者ユーザー（最大10件）
  # 3) MAIL_FROM（最後の保険）
  # =======================
  def admin_recipients
    env = ENV["ADMIN_EMAIL"].to_s.split(/\s*,\s*/).reject(&:blank?)
    return env if env.present?

    admins = User.where(admin: true).limit(10).pluck(:email).compact
    return admins if admins.present?

    [ ENV.fetch("MAIL_FROM", "no-reply@example.com") ]
  end

  # =======================
  # 管理者の表示名一覧
  # -----------------------
  # 表示名が無い/空の場合のフォールバックあり
  # =======================
  def admin_names
    names = User.where(admin: true).order(:id).pluck(:name).compact_blank
    names.presence || [ "管理者各位" ]
  end
end

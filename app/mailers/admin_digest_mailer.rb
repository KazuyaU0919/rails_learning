class AdminDigestMailer < ApplicationMailer
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

  def admin_recipients
    env = ENV["ADMIN_EMAIL"].to_s.split(/\s*,\s*/).reject(&:blank?)
    return env if env.present?

    admins = User.where(admin: true).limit(10).pluck(:email).compact
    return admins if admins.present?

    [ ENV.fetch("MAIL_FROM", "no-reply@example.com") ]
  end

  def admin_names
    names = User.where(admin: true).order(:id).pluck(:name).compact_blank
    names.presence || [ "管理者各位" ]
  end
end

# ============================================================
# Base Mailer
# ------------------------------------------------------------
# すべてのMailerの共通設定。
# 既定の送信元は ENV["MAIL_FROM"]（なければ指定のGmail）
# レイアウトは "mailer" を使用。
# ============================================================
class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAIL_FROM", "railslearning.developer0919@gmail.com")
  layout "mailer"
end

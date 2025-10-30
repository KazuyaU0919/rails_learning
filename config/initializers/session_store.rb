# =========================================================
# File: config/initializers/session_store.rb
# ---------------------------------------------------------
# 目的:
#   セッションストアの方式と属性（Cookie名・SameSite・Secure）を統一設定する。
#
# セキュリティ:
#   - same_site: :lax … 既定だが明示し CSRF リスクを下げる（クロスサイト送信で Cookie を送らない）。
#   - secure: 本番では HTTPS 通信時のみ Cookie を送信。
#
# 注意:
#   - key はアプリごとにユニークにし、ドメイン衝突を避ける。
# =========================================================

Rails.application.config.session_store :cookie_store,
  key: "_railslearning_session",  # アプリごとにユニークな Cookie 名
  same_site: :lax,               # 既定だが明示（クロスサイト送信を抑制）
  secure: Rails.env.production?   # 本番のみ HTTPS で送信

Rails.application.config.session_store :cookie_store,
  key: "_railslearning_session",              # アプリごとにユニークな名前に
  same_site: :lax,                      # デフォルト値だが明示しておく
  secure: Rails.env.production?         # 本番は HTTPS のみ送信

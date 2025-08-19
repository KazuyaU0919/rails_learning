Rails.application.routes.draw do
  get "tests/index"
  root "tests#index"

  # Render のヘルスチェック用
  get "up" => "rails/health#show", as: :rails_health_check

  resources :users, only: %i[new create]               # 登録フォーム/登録処理
  resource  :session, only: %i[new create destroy]     # ログイン/ログアウト
  resources :password_resets, only: %i[new create edit update]  # パス再設定用

  # OmniAuth
  get "/auth/:provider", to: "omni_auth#passthru", as: :auth,
                        constraints: { provider: /(google_oauth2|github)/ }
  get "/auth/:provider/callback", to: "omni_auth#callback", as: :omni_auth_callback
  get "/auth/failure",            to: "omni_auth#failure", as: :omni_auth_failure
end

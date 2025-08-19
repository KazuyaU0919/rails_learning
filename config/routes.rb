Rails.application.routes.draw do
  get "tests/index"
  root "tests#index"

  # Render のヘルスチェック用
  get "up" => "rails/health#show", as: :rails_health_check

  resources :users, only: %i[new create]               # 登録フォーム/登録処理
  resource  :session, only: %i[new create destroy]     # ログイン/ログアウト
  resources :password_resets, only: %i[new create edit update]  # パス再設定用

  # OmniAuth
  get "/auth/:provider/callback", to: "omniauth_callbacks#create"
  get "/auth/failure",            to: "omniauth_callbacks#failure"
end

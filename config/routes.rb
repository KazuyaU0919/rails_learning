Rails.application.routes.draw do
  get "book_sections/show"
  get "books/index"
  get "books/show"
  get "tests/index"

  # Render のヘルスチェック用
  get "up" => "rails/health#show", as: :rails_health_check

  # 認証機能
  resources :users, only: %i[new create]               # 登録フォーム/登録処理
  resource  :session, only: %i[new create destroy]     # ログイン/ログアウト
  resources :password_resets, only: %i[new create edit update]  # パス再設定用

  # PreCode機能
  concern :paginatable do
    # /pre_codes/page/2 → index の2ページ目に到達
    get "(page/:page)", action: :index, on: :collection, as: "", constraints: { page: /\d+/ }
  end

  resources :pre_codes, concerns: :paginatable

  # === Code Library ===
  resources :code_libraries, only: %i[index show], concerns: :paginatable
  resources :likes,      only: %i[create destroy]
  resources :used_codes, only: %i[create]

  # Code Editor
  root "editor#index"
  get  "/editor", to: "editor#index",  as: :editor
  post "/editor", to: "editor#create"
  get "/pre_codes/:id/body",
      to: "editor#pre_code_body",
      as: :pre_code_body,
      constraints: { id: /\d+/ }

  # Rails Books
  resources :books, only: %i[index show] do
    resources :sections, only: :show, controller: :book_sections
  end

  # OmniAuth
  get "/auth/:provider", to: "omni_auth#passthru", as: :auth,
                         constraints: { provider: /(google_oauth2|github)/ }
  get "/auth/:provider/callback", to: "omni_auth#callback", as: :omni_auth_callback
  get "/auth/failure",            to: "omni_auth#failure", as: :omni_auth_failure
end

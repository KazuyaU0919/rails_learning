Rails.application.routes.draw do
  namespace :quizzes do
    namespace :sections do
      get "questions/show"
    end
    get "sections/index"
    get "sections/show"
  end
  get "quizzes/index"
  get "quizzes/show"
  # 静的ページ
  get "help",    to: "static_pages#help"
  get "terms",   to: "static_pages#terms"
  get "privacy", to: "static_pages#privacy"
  get "contact", to: "static_pages#contact"
  get "/search/suggest", to: "searches#suggest"  # オートコンプリートAPI
  get "tests/index"

  # Render のヘルスチェック用
  get "up" => "rails/health#show", as: :rails_health_check

  # 認証機能
  resources :users, only: %i[new create]               # 登録フォーム/登録処理
  resource  :session, only: %i[new create destroy]     # ログイン/ログアウト
  resources :password_resets, only: %i[new create edit update]  # パス再設定用

  # ユーザープロフィール
  resource :profile, only: %i[show edit update] do
    post :revoke_remember   # /profile/revoke_remember
  end

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

  # ブックマーク機能
  resources :bookmarks, only: %i[create destroy]

  # タグ
  resources :tags, only: %i[index show]

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

  # クイズ機能
  resources :quizzes, only: %i[index show] do
    resources :sections, only: %i[index show], module: :quizzes do
      resources :questions, only: %i[show], module: :sections do
        post :answer, on: :member
        get  :answer_page, on: :member
      end
      get :result, on: :member
    end
  end

  # 管理画面
  namespace :admin do
    get "quiz_questions/index"
    get "quiz_questions/show"
    get "quiz_questions/new"
    get "quiz_questions/create"
    get "quiz_questions/edit"
    get "quiz_questions/update"
    get "quiz_questions/destroy"
    get "quiz_sections/index"
    get "quiz_sections/show"
    get "quiz_sections/new"
    get "quiz_sections/create"
    get "quiz_sections/edit"
    get "quiz_sections/update"
    get "quiz_sections/destroy"
    get "quizzes/index"
    get "quizzes/show"
    get "quizzes/new"
    get "quizzes/create"
    get "quizzes/edit"
    get "quizzes/update"
    get "quizzes/destroy"
    root "dashboards#index"

    resource  :session,   only: %i[new create destroy]
    resources :books
    resources :book_sections, except: %i[show]
    resources :pre_codes, only: %i[index show edit update destroy]
    resources :quizzes
    resources :quiz_sections
    resources :quiz_questions

    resources :users, only: [ :index, :destroy ] do
      member do
        patch :toggle_editor
        patch :toggle_ban
      end
    end

    resources :tags, only: %i[index destroy] do
      post :merge, on: :collection
    end
  end

  # letter_opener
  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end

  # OmniAuth
  get "/auth/:provider", to: "omni_auth#passthru", as: :auth,
                         constraints: { provider: /(google_oauth2|github)/ }
  get "/auth/:provider/callback", to: "omni_auth#callback", as: :omni_auth_callback
  get "/auth/failure",            to: "omni_auth#failure", as: :omni_auth_failure
end

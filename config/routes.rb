Rails.application.routes.draw do
  get "tests/index"
  root "tests#index"

  # Render のヘルスチェック用
  get "up" => "rails/health#show", as: :rails_health_check
end

# config/initializers/kaminari_config.rb
Kaminari.configure do |config|
  config.default_per_page = 10   # 既定件数
  config.window = 1              # 現在ページ左右に出すページ数
  config.outer_window = 1        # 先頭/末尾側に出すページ数
  # config.param_name = :page    # パラメータ名を変えたいとき
end

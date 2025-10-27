# =========================================================
# File: config/initializers/kaminari_config.rb
# ---------------------------------------------------------
# 目的:
#   ページネーションライブラリ Kaminari の共通設定。
#
# 指針:
#   - 1ページあたり件数やページリンクの表示幅を統一。
#   - 画面の利用状況に応じて default_per_page 等を調整可能。
# =========================================================

# config/initializers/kaminari_config.rb
Kaminari.configure do |config|
  # =======================
  # ページネーション表示設定
  # =======================
  config.default_per_page = 10   # 既定件数
  config.window = 1              # 現在ページ左右に出すページ数
  config.outer_window = 1        # 先頭/末尾側に出すページ数
  # config.param_name = :page    # パラメータ名を変えたいとき
end

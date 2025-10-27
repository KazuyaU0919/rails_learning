# =========================================================
# File: config/environment.rb
# ---------------------------------------------------------
# 目的:
#   Rails アプリケーションを初期化するエントリポイント。
#   application.rb の設定を読み込み、初期化処理を走らせる。
#
# 注意:
#   - コードは標準的な 2 行構成。変更は行っていない。
# =========================================================

# Load the Rails application.
require_relative "application"

# Initialize the Rails application.
Rails.application.initialize!

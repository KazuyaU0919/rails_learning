# =========================================================
# File: config/initializers/assets.rb
# ---------------------------------------------------------
# 目的:
#   - アセットパイプライン（Sprockets）の設定。
#   - バージョン管理・ロードパス設定など。
# =========================================================

# アセットのバージョン指定（キャッシュクリア用途）
Rails.application.config.assets.version = "1.0"

# 追加パスを設定する場合は以下を利用
# Rails.application.config.assets.paths << Emoji.images_path

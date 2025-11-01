# =========================================================
# File: config/boot.rb
# ---------------------------------------------------------
# 目的:
#   Bundler（Gem）と Bootsnap（起動高速化）の初期化。
#
# 注意:
#   - BUNDLE_GEMFILE が未設定ならプロジェクトの Gemfile を指すように設定。
#   - bootsnap は高コストな処理をキャッシュしてブート時間を短縮。
# =========================================================

ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

require "bundler/setup"   # Set up gems listed in the Gemfile.
require "bootsnap/setup"  # Speed up boot time by caching expensive operations.

# =========================================================
# File: config/application.rb
# ---------------------------------------------------------
# 目的:
#   Rails アプリ全体の共通設定。環境別（development/test/production）は
#   environments/ 以下で個別にオーバーライド。
#
# 主な構成:
#   - フレームワーク読込/初期化値
#   - 自動ロード/キュー/国際化/時刻・タイムゾーン
#   - ActiveStorage/ActiveRecord の時間扱い
#   - アセットパス
#   - ジェネレーター設定（RSpec 前提）
# =========================================================

require_relative "boot"
require "rails/all"

# Gemfile の :test/:development/:production グループを読み込む
Bundler.require(*Rails.groups)

module RailsLearning
  class Application < Rails::Application
    # =======================
    # Rails 既定値の初期化
    # =======================
    # 生成当時のメジャーバージョンに合わせた既定を読み込む
    config.load_defaults 8.0

    # =======================
    # オートロード設定
    # =======================
    # lib 配下のうち、assets / tasks は無視（再読込や eager_load の対象外）
    config.autoload_lib(ignore: %w[assets tasks])

    # =======================
    # Active Job
    # =======================
    # 即時実行（インライン）アダプタを使用
    config.active_job.queue_adapter = :inline

    # =======================
    # i18n / タイムゾーン
    # =======================
    config.i18n.default_locale = :ja
    config.time_zone = "Asia/Tokyo"           # アプリの基準タイムゾーン
    config.active_record.default_timezone = :utc
    config.time_zone_aware_attributes = true  # タイムゾーン対応の属性を Time.zone で扱う

    # =======================
    # Active Storage
    # =======================
    # バリアント生成に vips を使う（高速・省メモリ）
    config.active_storage.variant_processor = :vips

    # =======================
    # アセットパス
    # =======================
    # build されたアセットを明示的にパスへ追加
    # NOTE: 同一パスを `<<` と `unshift` の両方で指定しているが、既存の挙動を保持
    config.assets.paths << Rails.root.join("app/assets/builds")
    config.assets.paths.unshift Rails.root.join("app/assets/builds")

    # =======================
    # ジェネレータ設定（RSpec 前提）
    # =======================
    config.generators do |g|
      g.test_framework :rspec,
        fixtures: true,          # fixture/FactoryBot を使う前提
        view_specs: false,       # view spec は自動生成しない
        helper_specs: false,     # helper spec は自動生成しない
        routing_specs: false,    # routing spec は自動生成しない
        controller_specs: false, # 旧来の controller spec は自動生成しない
        request_specs: true      # request spec を自動生成（推奨）

      g.fixture_replacement :factory_bot, dir: "spec/factories"
      g.system_tests nil         # Minitest の system test は作らない
    end
  end
end

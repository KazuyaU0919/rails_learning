# config/initializers/paper_trail_retention.rb
# PaperTrail の自動クリーンアップ設定
Rails.application.configure do
  config.x.versions.keep_per_item = ENV.fetch("VERSIONS_KEEP_PER_ITEM", 100).to_i       # 各 item の最大保持件数
  config.x.versions.keep_days     = ENV.fetch("VERSIONS_KEEP_DAYS", 30).to_i            # 何日以内を保持するか
  config.x.versions.cleanup_batch = ENV.fetch("VERSIONS_CLEANUP_BATCH", 1000).to_i      # 1回の削除件数
end

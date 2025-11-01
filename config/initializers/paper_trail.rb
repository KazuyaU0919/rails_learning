# =========================================================
# File: config/initializers/paper_trail.rb
# ---------------------------------------------------------
# 目的:
#   PaperTrail のシリアライザを JSON に統一。
#
# 背景:
#   YAML は安全読み込みの考慮が必要なため、より安全な JSON を利用。
#   既存データとの互換は PaperTrail の仕様に準拠。
# =========================================================

# config/initializers/paper_trail.rb
PaperTrail.configure do |config|
  # 新規以降は JSON で保存（YAML の安全読み込み問題を回避）
  config.serializer = PaperTrail::Serializers::JSON
end

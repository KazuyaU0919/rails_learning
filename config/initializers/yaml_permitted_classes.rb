# =========================================================
# File: config/initializers/yaml_permitted_classes.rb
# ---------------------------------------------------------
# 目的:
#   ActiveRecord の YAML カラムで「安全にデシリアライズを許可するクラス」を追加。
#   Rails 7.1+ の推奨 API があればそれを使い、なければ後方互換 API で設定する。
#
# ポイント:
#   - YAML の安全読み込みは取り扱いに注意。不要なクラスを許可しない。
#   - 既存データに必要な最小限のみを許可する。
#
# 構成:
#   1) 許可クラス配列の定義
#   2) Rails 7.1+ の API で設定
#   3) 旧来 API (ActiveRecord::Coders::YAMLColumn) でも設定
# =========================================================

# =======================
# 1) 許可クラスの定義
# =======================
permitted = [
  Time, Date, Symbol,
  ActiveSupport::TimeZone,
  ActiveSupport::TimeWithZone
]

# =======================
# 2) Rails 7.1+ 推奨 API
# =======================
if ActiveRecord.respond_to?(:yaml_column_permitted_classes)
  ActiveRecord.yaml_column_permitted_classes |= permitted
end

# =======================
# 3) 旧来 API（後方互換）
# =======================
if defined?(ActiveRecord::Coders::YAMLColumn) &&
   ActiveRecord::Coders::YAMLColumn.respond_to?(:permitted_classes=)
  current = ActiveRecord::Coders::YAMLColumn.permitted_classes || []
  ActiveRecord::Coders::YAMLColumn.permitted_classes = (current | permitted)
end

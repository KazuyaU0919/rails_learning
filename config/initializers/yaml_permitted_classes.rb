# config/initializers/yaml_permitted_classes.rb
# YAMLカラムで許可するクラスを追加
permitted = [
  Time, Date, Symbol,
  ActiveSupport::TimeZone,
  ActiveSupport::TimeWithZone
]

# Rails 7.1+ (推奨API)
if ActiveRecord.respond_to?(:yaml_column_permitted_classes)
  ActiveRecord.yaml_column_permitted_classes |= permitted
end

# 古いRails互換: YAMLColumnに直接設定
if defined?(ActiveRecord::Coders::YAMLColumn) &&
   ActiveRecord::Coders::YAMLColumn.respond_to?(:permitted_classes=)
  current = ActiveRecord::Coders::YAMLColumn.permitted_classes || []
  ActiveRecord::Coders::YAMLColumn.permitted_classes = (current | permitted)
end

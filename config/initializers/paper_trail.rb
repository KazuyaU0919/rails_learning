# config/initializers/paper_trail.rb
PaperTrail.configure do |config|
  # 新規以降は JSON で保存（YAML の安全読み込み問題を回避）
  config.serializer = PaperTrail::Serializers::JSON
end

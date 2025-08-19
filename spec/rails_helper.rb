# spec/rails_helper.rb
require 'spec_helper'

ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
abort('The Rails environment is running in production mode!') if Rails.env.production?

require 'rspec/rails'

# --- support配下の読み込み（必要なものを小分けにしたい場合は有効化）
# Dir[Rails.root.join('spec/support/**/*.rb')].sort.each { |f| require f }

# --- DBスキーマをテストDBに反映（ActiveRecordを使わないなら削除可）
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

RSpec.configure do |config|
  # fixtures を使うならパスを定義（FactoryBotのみなら削除可）
  config.fixture_paths = [ Rails.root.join('spec/fixtures') ]

  # 各exampleをトランザクションで囲む（通常は true のままでOK）
  config.use_transactional_fixtures = true

  # spec/ ディレクトリ構成から spec type を自動推定（request/model 等）
  config.infer_spec_type_from_file_location!

  # Rails由来のバックトレース行を省略して見やすく
  config.filter_rails_from_backtrace!

  # --- FactoryBot を短縮呼び出し（create, build など）
  config.include FactoryBot::Syntax::Methods
end

# --- shoulda-matchers（モデル/バリデーションの定番: 任意）
# Gemfile に `shoulda-matchers` を入れている場合のみ有効化
if defined?(Shoulda::Matchers)
  Shoulda::Matchers.configure do |config|
    config.integrate do |with|
      with.test_framework :rspec
      with.library :rails
    end
  end
end

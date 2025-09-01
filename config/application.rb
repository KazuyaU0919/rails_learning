require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module RailsLearning
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])
    config.active_job.queue_adapter = :inline
    config.i18n.default_locale = :ja
    config.active_storage.variant_processor = :vips
    config.time_zone = "Asia/Tokyo"
    config.active_record.default_timezone = :utc
    config.time_zone_aware_attributes = true

    config.generators do |g|
      g.test_framework :rspec,
        fixtures: true,          # fixture/FactoryBot を使う前提
        view_specs: false,       # view spec を自動生成しない
        helper_specs: false,     # helper spec を自動生成しない
        routing_specs: false,    # routing spec を自動生成しない
        controller_specs: false, # 旧来の controller spec を自動生成しない
        request_specs: true      # request spec を自動生成する（推奨）
      g.fixture_replacement :factory_bot, dir: "spec/factories"
      g.system_tests nil         # Minitest の system test は作らない
    end
  end
end

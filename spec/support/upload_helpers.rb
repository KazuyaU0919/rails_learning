# spec/support/upload_helpers.rb
# アップロード用のテストヘルパ
module UploadHelpers
  # 例) uploaded_image            -> spec/fixtures/files/sample.png (image/png)
  #     uploaded_image("a.jpg")   -> spec/fixtures/files/a.jpg     (image/jpeg 推定されないので type 指定推奨)
  def uploaded_image(filename = "sample.png", type: "image/png")
    path = Rails.root.join("spec/fixtures/files", filename)
    Rack::Test::UploadedFile.new(path, type)
  end
end

RSpec.configure do |config|
  config.include UploadHelpers
end

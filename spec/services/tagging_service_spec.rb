# spec/services/tagging_service_spec.rb
require "rails_helper"
RSpec.describe TaggingService do
  let(:user) { create(:user) }
  let(:pc)   { create(:pre_code, user:) }

  it "既存タグを再利用して付与" do
    t = create(:tag, name: "Ruby")
    TaggingService.new(pc, current_user: user).apply!([ "ruby" ])
    expect(pc.tags).to match_array([ t ])
  end

  it "新規タグを作成して付与（最大10個に丸める）" do
    names = (1..12).map { |i| "t#{i}" }
    TaggingService.new(pc, current_user: user).apply!(names)
    expect(pc.tags.count).to eq(10)
  end
end

# spec/models/tag_spec.rb
require "rails_helper"

RSpec.describe Tag, type: :model do
  it "name_norm が一意になる" do
    create(:tag, name: "Ruby")
    expect { create(:tag, name: " ruby ") }.to raise_error(ActiveRecord::RecordInvalid)
  end

  describe ".cleanup_unused!" do
    it "zero_since が10日以上の未使用タグを削除する" do
      old_unused = create(:tag, name: "old-zero")
      recent_unused = create(:tag, name: "recent-zero")
      used = create(:tag, name: "used")

      # 擬似的に zero を設定
      old_unused.update!(taggings_count: 0, zero_since: 11.days.ago)
      recent_unused.update!(taggings_count: 0, zero_since: 5.days.ago)
      used.update!(taggings_count: 1, zero_since: nil)

      expect {
        Tag.cleanup_unused!(older_than: 10.days)
      }.to change(Tag, :count).by(-1)

      expect(Tag.exists?(old_unused.id)).to be_falsey
      expect(Tag.exists?(recent_unused.id)).to be_truthy
      expect(Tag.exists?(used.id)).to be_truthy
    end
  end
end

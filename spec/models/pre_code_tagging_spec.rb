# spec/models/pre_code_tagging_spec.rb
require "rails_helper"

RSpec.describe PreCodeTagging, type: :model do
  it "pre_code と tag の組が一意" do
    pc = create(:pre_code)
    tag = create(:tag)
    create(:pre_code_tagging, pre_code: pc, tag: tag)
    expect { create(:pre_code_tagging, pre_code: pc, tag: tag) }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it "作成/削除で tag.zero_since が適切に更新される" do
    pc  = create(:pre_code)
    tag = create(:tag)

    # 作成で使用開始 → zero_since は nil
    create(:pre_code_tagging, pre_code: pc, tag: tag)
    expect(tag.reload.zero_since).to be_nil
    expect(tag.taggings_count).to eq(1)

    # 削除で未使用化 → zero_since が入る
    PreCodeTagging.where(pre_code: pc, tag: tag).first.destroy!
    expect(tag.reload.taggings_count).to eq(0)
    expect(tag.zero_since).to be_present

    # 再度使用開始 → zero_since は nil に戻る
    create(:pre_code_tagging, pre_code: pc, tag: tag)
    expect(tag.reload.taggings_count).to eq(1)
    expect(tag.zero_since).to be_nil
  end
end

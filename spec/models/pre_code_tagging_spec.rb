# spec/models/pre_code_tagging_spec.rb
require "rails_helper"
RSpec.describe PreCodeTagging, type: :model do
  it "pre_code と tag の組が一意" do
    pc = create(:pre_code)
    tag = create(:tag)
    create(:pre_code_tagging, pre_code: pc, tag: tag)
    expect { create(:pre_code_tagging, pre_code: pc, tag: tag) }.to raise_error(ActiveRecord::RecordInvalid)
  end
end

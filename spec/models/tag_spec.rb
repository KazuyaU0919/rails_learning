# spec/models/tag_spec.rb
require "rails_helper"
RSpec.describe Tag, type: :model do
  it "name_norm が一意になる" do
    create(:tag, name: "Ruby")
    expect { create(:tag, name: " ruby ") }.to raise_error(ActiveRecord::RecordInvalid)
  end
end

# spec/models/bookmark_spec.rb
require "rails_helper"

RSpec.describe Bookmark, type: :model do
  it "user と pre_code の組が一意" do
    b = create(:bookmark)
    expect { create(:bookmark, user: b.user, pre_code: b.pre_code) }
      .to raise_error(ActiveRecord::RecordInvalid)
  end
end

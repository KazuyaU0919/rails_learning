# spec/models/book_spec.rb
require "rails_helper"

RSpec.describe Book, type: :model do
  describe "validations" do
    it "is valid with title, description and position" do
      expect(build(:book)).to be_valid
    end

    it "is invalid without title" do
      b = build(:book, title: "")
      expect(b).to be_invalid
      expect(b.errors[:title]).to be_present
    end

    it "is invalid when description is over 500 chars" do
      b = build(:book, description: "a" * 501)
      expect(b).to be_invalid
      expect(b.errors[:description]).to be_present
    end

    it "validates position is integer > 0" do
      b = build(:book, position: 0)
      expect(b).to be_invalid
      expect(b.errors[:position]).to be_present

      b2 = build(:book, position: 1.5)
      expect(b2).to be_invalid
      expect(b2.errors[:position]).to be_present
    end

    it "validates position uniqueness" do
      create(:book, position: 10)
      dup = build(:book, position: 10)
      expect(dup).to be_invalid
      expect(dup.errors[:position]).to be_present
    end
  end

  describe "associations" do
    it "orders book_sections by position due to association scope" do
      book = create(:book)
      create(:book_section, book:, position: 2)
      create(:book_section, book:, position: 0)
      create(:book_section, book:, position: 1)

      expect(book.book_sections.pluck(:position)).to eq([ 0, 1, 2 ])
    end

    it "destroys book_sections when book is destroyed" do
      book = create(:book)
      create(:book_section, book:)
      expect { book.destroy }.to change { BookSection.count }.by(-1)
    end
  end
end

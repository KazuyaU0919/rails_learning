# app/services/book_sections/renumber.rb
class BookSections::Renumber
  def self.call(book)
    book.book_sections.order(:position).each_with_index do |s, idx|
      s.update_columns(position: idx + 1) if s.position != idx + 1
    end
  end
end

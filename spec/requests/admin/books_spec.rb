# spec/requests/admin/books_spec.rb
require "rails_helper"

RSpec.describe "Admin::Books", type: :request do
  let(:admin) { create(:user, admin: true) }

  before { sign_in_as(admin, password: "secret123") }

  it "GET /admin/books works" do
    get admin_books_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Books")
  end

  it "POST /admin/books creates a book" do
    post admin_books_path, params: { book: { title: "T", description: "D" } }
    expect(response).to redirect_to(admin_books_path)
    follow_redirect!
    expect(response.body).to include("作成しました")
  end

  it "PATCH /admin/books/:id updates a book" do
    book = create(:book, title: "Old", description: "Desc")
    patch admin_book_path(book), params: { book: { title: "New" } }
    expect(response).to redirect_to(admin_books_path)
    follow_redirect!
    expect(response.body).to include("更新しました")
  end

  it "DELETE /admin/books/:id removes a book" do
    book = create(:book)
    delete admin_book_path(book)
    expect(response).to redirect_to(admin_books_path)
    follow_redirect!
    expect(response.body).to include("削除しました")
  end
end

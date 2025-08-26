# config/breadcrumbs.rb

# ============================================================
# 共通（サイト共通の最上位）
# ============================================================
crumb :root do
  link "ホーム", root_path
end


# ============================================================
# 一般（Public）エリア
# ============================================================

# --- Code Editor ---
crumb :editor do
  parent :root
  link "Code Editor", editor_path
end

# --- Rails Books ---
crumb :books do
  parent :root
  link "Rails Books", books_path
end

crumb :book do |book|
  parent :books
  link book.title, book_path(book)
end

# 本の中の Section（公開側）
crumb :book_section do |book, section|
  parent :book, book
  # 例）"2. 環境構築"
  link "#{section.position}. #{section.heading}", book_section_path(book, section)
end

# --- PreCode ---
crumb :pre_codes do
  parent :root
  link "PreCode", pre_codes_path
end

crumb :pre_code do |code|
  parent :pre_codes
  link code.title, pre_code_path(code)
end

crumb :pre_code_new do
  parent :pre_codes
  link "新規作成", new_pre_code_path
end

crumb :pre_code_edit do |code|
  parent :pre_codes
  link "#{code.title}：編集", edit_pre_code_path(code)
end

# --- Code Library ---
crumb :code_libraries do
  parent :root
  link "Code Library", code_libraries_path
end

crumb :code_library do |lib|
  parent :code_libraries
  link lib.title, code_library_path(lib)
end


# ============================================================
# 管理（Admin）エリア
# ============================================================

# ダッシュボード（管理の起点）
crumb :admin_root do
  parent :root
  link "ダッシュボード", admin_root_path
end

# --- Admin: Books ---
crumb :admin_books do
  parent :admin_root
  link "Books", admin_books_path
end

# 管理側 Book 詳細（show が無いなら edit にしてOK）
crumb :admin_book do |book|
  parent :admin_books
  link book.title, admin_book_path(book) # showが無ければ edit_admin_book_path(book) に変更可
end

# 管理側 Book 編集（「タイトル：編集」表記）
crumb :admin_book_edit do |book|
  parent :admin_books
  link "#{book.title}：編集", edit_admin_book_path(book)
end

# --- Admin: Sections ---
crumb :admin_book_sections do
  parent :admin_root
  link "Sections", admin_book_sections_path
end

# 管理側 Section 詳細（show が無ければ edit にしてOK）
crumb :admin_book_section do |section|
  parent :admin_book_sections
  link section.heading, admin_book_section_path(section) # showが無ければ edit_admin_book_section_path(section)
end

# 管理側 Section 編集（「見出し：編集」表記）
crumb :admin_book_section_edit do |section|
  parent :admin_book_sections
  link "#{section.heading}：編集", edit_admin_book_section_path(section)
end

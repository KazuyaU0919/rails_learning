# ============================================================
# File: config/breadcrumbs.rb
# ------------------------------------------------------------
# 目的:
#   アプリ全体のパンくず（breadcrumbs）を宣言的に定義する。
#   画面ごとに `breadcrumb :symbol` を呼ぶと、ここで定義した
#   パンくずの階層・ラベル・リンクがレンダリング時に適用される。
#
# 設計方針:
#   - 「サイト共通」→「公開（Public）」→「管理（Admin）」の順に整理。
#   - 各リソースは「一覧 → 詳細 → 新規 → 編集」の順で並べる。
#   - 一部、URLヘルパに必要なIDが手元にない場面があるため、
#     params フォールバックを用意（※“応急処置”と明記）。
#     これは挙動維持のための暫定で、将来的にはコントローラ側で
#     必要オブジェクトを必ず渡すように改善予定。
#
# 使い方（例）:
#   <% breadcrumb :books %>
#   <% breadcrumb :book, @book %>
#   <%= render "shared/breadcrumbs" %>
# ============================================================


# ============================================================
# =======================
# サイト共通（最上位）
# =======================
# - すべてのルートの親となる「ホーム」
# ============================================================
crumb :root do
  link "ホーム", root_path
end


# ============================================================
# =======================
# 公開（Public）エリア
# =======================
# 構成:
#   1) Editor（トップ）
#   2) Rails Books（一覧→詳細→Section閲覧→Section編集）
#   3) PreCode（一覧→詳細→新規→編集）
#   4) Code Library（一覧→詳細）
#   5) 静的ページ（使い方/規約/プライバシー/問い合わせ）
#   6) プロフィール（表示→編集）
#   7) Quizzes（一覧→クイズ→セクション一覧→セクション表示/結果→問題→解答ページ→問題編集→空クイズ）
# ============================================================

# -----------------------
# 1) Editor（トップ）
# -----------------------
crumb :editor do
  parent :root
  link "Code Editor", editor_path
end

# -----------------------
# 2) Rails Books
# -----------------------

# 一覧
crumb :books do
  parent :root
  link "Rails Books", books_path
end

# 詳細（Book）
crumb :book do |book|
  parent :books
  link book.title, book_path(book)
end

# Section 閲覧（公開側）
crumb :book_section do |book, section|
  parent :book, book
  link "#{section.position}. #{section.heading}", book_section_path(book, section)
end

# Section 編集（公開側の編集ルート）
crumb :book_section_edit do |book, section|
  parent :book, book
  link "#{section.position}. #{section.heading}：編集", edit_book_section_path(book, section)
end

# -----------------------
# 3) PreCode
# -----------------------

# 一覧
crumb :pre_codes do
  parent :root
  link "PreCode", pre_codes_path
end

# 詳細
crumb :pre_code do |code|
  parent :pre_codes
  link code.title, pre_code_path(code)
end

# 新規
crumb :pre_code_new do
  parent :pre_codes
  link "新規作成", new_pre_code_path
end

# 編集
crumb :pre_code_edit do |code|
  parent :pre_code, code
  link "編集", edit_pre_code_path(code)
end

# -----------------------
# 4) Code Library
# -----------------------

# 一覧
crumb :code_libraries do
  parent :root
  link "Code Library", code_libraries_path
end

# 詳細
crumb :code_library do |lib|
  parent :code_libraries
  link lib.title, code_library_path(lib)
end

# -----------------------
# 5) 静的ページ
# -----------------------
crumb :help do
  parent :root
  link "アプリの使い方", help_path
end

crumb :terms do
  parent :root
  link "利用規約", terms_path
end

crumb :privacy do
  parent :root
  link "プライバシーポリシー", privacy_path
end

crumb :contact do
  parent :root
  link "お問い合わせ", contact_path
end

# -----------------------
# 6) プロフィール
# -----------------------
crumb :profile do
  parent :root
  link "プロフィール", profile_path
end

crumb :profile_edit do
  parent :profile
  link "編集", edit_profile_path
end

# -----------------------
# 7) Quizzes（公開）
# -----------------------

# クイズ一覧
crumb :quizzes do
  parent :root
  link "クイズ一覧", quizzes_path
end

# クイズ詳細（トップ）
crumb :quiz do |quiz|
  parent :quizzes
  link quiz.title, quiz_path(quiz)
end

# セクション一覧（/quizzes/:quiz_id/sections）
crumb :quiz_sections do |quiz|
  parent :quiz, quiz
  link "セクション一覧", quiz_sections_path(quiz)
end

# セクション詳細（/quizzes/:quiz_id/sections/:id）
# 応急処置: quiz/section が nil の場合、params を参照して ID を埋める。
crumb :quiz_section_public do |quiz, section|
  parent :quiz, quiz
  qid = (quiz && quiz.respond_to?(:id)) ? quiz.id : params[:quiz_id]
  sid = (section && section.respond_to?(:id)) ? section.id : (params[:section_id] || params[:id])
  link "セクション ##{sid}", quiz_section_path(qid, sid)
end

# 問題表示（/quizzes/:quiz_id/sections/:section_id/questions/:id）
crumb :quiz_question do |quiz, section, question|
  parent :quiz_section_public, quiz, section
  link "問題", quiz_section_question_path(quiz, section, question)
end

# 解答・解説ページ（answer_page）
crumb :quiz_question_answer_page do |quiz, section, question|
  parent :quiz_question, quiz, section, question
  link "解答・解説", answer_page_quiz_section_question_path(quiz, section, question)
end

# セクション結果（/quizzes/:quiz_id/sections/:id/result）
# 応急処置: params フォールバックでIDを解決。
crumb :quiz_section_result do |quiz, section|
  parent :quiz_section_public, quiz, section
  qid = (quiz && quiz.respond_to?(:id)) ? quiz.id : params[:quiz_id]
  sid = (section && section.respond_to?(:id)) ? section.id : (params[:section_id] || params[:id])
  link "結果", result_quiz_section_path(qid, sid)
end

# 問題編集（公開側）
crumb :quiz_question_edit do |quiz, section, question|
  parent :quiz_question, quiz, section, question
  link "編集", edit_quiz_section_question_path(quiz, section, question)
end

# URLが無い想定の空画面（表示のみ）
crumb :quiz_empty do
  parent :quizzes
  link "空のクイズ", nil
end


# ============================================================
# =======================
# 管理（Admin）エリア
# =======================
# 構成:
#   0) ダッシュボード（起点）
#   1) Users
#   2) Books（一覧→詳細→新規→編集）
#   3) Book Sections（一覧→詳細→新規→編集）
#   4) PreCodes（一覧→詳細→編集）
#   5) Tags（一覧）
#   6) Quizzes（一覧→詳細→新規→編集）
#   7) Quiz Sections（一覧→詳細→新規→編集）
#   8) Quiz Questions（一覧→詳細→新規→編集）
#   9) Editor Permissions（一覧→新規→一括→詳細→編集）
#  10) Versions（一覧→詳細）
# ============================================================

# -----------------------
# 0) ダッシュボード
# -----------------------
crumb :admin_root do
  parent :root
  link "ダッシュボード", admin_root_path
end

# -----------------------
# 1) Users
# -----------------------
crumb :admin_users do
  parent :admin_root
  link "ユーザー管理", admin_users_path
end

# -----------------------
# 2) Books
# -----------------------
crumb :admin_books do
  parent :admin_root
  link "Books", admin_books_path
end

crumb :admin_book do |book|
  parent :admin_books
  link book.title, admin_book_path(book) # show が無ければ edit に差し替え
end

crumb :admin_book_new do
  parent :admin_books
  link "新規作成", new_admin_book_path
end

crumb :admin_book_edit do |book|
  parent :admin_books
  link "#{book.title}：編集", edit_admin_book_path(book)
end

# -----------------------
# 3) Book Sections
# -----------------------
crumb :admin_book_sections do
  parent :admin_root
  link "Sections", admin_book_sections_path
end

crumb :admin_book_section do |section|
  parent :admin_book_sections
  link section.heading, admin_book_section_path(section) # show が無ければ edit に差し替え
end

crumb :admin_book_section_new do
  parent :admin_book_sections
  link "新規作成", new_admin_book_section_path
end

crumb :admin_book_section_edit do |section|
  parent :admin_book_sections
  link "#{section.heading}：編集", edit_admin_book_section_path(section)
end

# -----------------------
# 4) PreCodes
# -----------------------
crumb :admin_pre_codes do
  parent :admin_root
  link "PreCode 管理", admin_pre_codes_path
end

crumb :admin_pre_code do |code|
  parent :admin_pre_codes
  link code.title, admin_pre_code_path(code)
end

crumb :admin_pre_code_edit do |code|
  parent :admin_pre_codes
  link "#{code.title}：編集", edit_admin_pre_code_path(code)
end

# -----------------------
# 5) Tags
# -----------------------
crumb :admin_tags do
  parent :admin_root
  link "タグ管理", admin_tags_path
end

# -----------------------
# 6) Quizzes（作成系）
# -----------------------
crumb :admin_quizzes do
  parent :admin_root
  link "クイズ（作成）", admin_quizzes_path
end

crumb :admin_quiz_new do
  parent :admin_quizzes
  link "新規作成", new_admin_quiz_path
end

crumb :admin_quiz do |quiz|
  parent :admin_quizzes
  link quiz.title, admin_quiz_path(quiz)
end

crumb :admin_quiz_edit do |quiz|
  parent :admin_quizzes
  link "#{quiz.title}：編集", edit_admin_quiz_path(quiz)
end

# -----------------------
# 7) Quiz Sections
# -----------------------
crumb :admin_quiz_sections do
  parent :admin_root
  link "クイズ Sections", admin_quiz_sections_path
end

crumb :admin_quiz_section_new do
  parent :admin_quiz_sections
  link "新規作成", new_admin_quiz_section_path
end

crumb :admin_quiz_section do |section|
  parent :admin_quiz_sections
  link section.title, admin_quiz_section_path(section)
end

# 応急処置: section が nil の場合、params[:id] で編集ページにリンク。
crumb :admin_quiz_section_edit do |section|
  parent :admin_quiz_sections
  sid = (section && section.respond_to?(:id)) ? section.id : params[:id]
  link "セクション ##{sid}：編集", edit_admin_quiz_section_path(sid)
end

# -----------------------
# 8) Quiz Questions
# -----------------------
crumb :admin_quiz_questions do
  parent :admin_root
  link "クイズ Questions", admin_quiz_questions_path
end

crumb :admin_quiz_question_new do
  parent :admin_quiz_questions
  link "新規作成", new_admin_quiz_question_path
end

crumb :admin_quiz_question do |question|
  parent :admin_quiz_questions
  link "問題 ##{question.id}", admin_quiz_question_path(question)
end

# 応急処置: question が nil の場合、params[:id] を表示に利用。
crumb :admin_quiz_question_edit do |question|
  parent :admin_quiz_questions
  qid = (question && question.respond_to?(:id)) ? question.id : params[:id]
  link "問題 ##{qid}：編集", edit_admin_quiz_question_path(qid)
end

# -----------------------
# 9) Editor Permissions
# -----------------------
crumb :admin_editor_permissions do
  parent :admin_root
  link "Editor Permissions", admin_editor_permissions_path
end

crumb :new_admin_editor_permission do
  parent :admin_editor_permissions
  link "新規作成", new_admin_editor_permission_path
end

crumb :bulk_new_admin_editor_permissions do
  parent :admin_editor_permissions
  link "一括付与", bulk_new_admin_editor_permissions_path
end

# 応急処置: perm が nil の場合、params[:id] でラベルを生成。
crumb :admin_editor_permission do |perm|
  parent :admin_editor_permissions
  pid = (perm && perm.respond_to?(:id)) ? perm.id : params[:id]
  link "##{pid}", admin_editor_permission_path(pid)
end

crumb :edit_admin_editor_permission do |perm|
  parent :admin_editor_permissions
  pid = (perm && perm.respond_to?(:id)) ? perm.id : params[:id]
  link "##{pid}：編集", edit_admin_editor_permission_path(pid)
end

# -----------------------
# 10) Versions（バージョン管理）
# -----------------------
crumb :admin_versions do
  parent :admin_root
  link "変更履歴", admin_versions_path
end

crumb :admin_version do |version|
  parent :admin_versions
  link "##{version.id}", admin_version_path(version)
end

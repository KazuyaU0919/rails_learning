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

# --- Editor（トップ） ---
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

# 公開側 Section（閲覧）
crumb :book_section do |book, section|
  parent :book, book
  link "#{section.position}. #{section.heading}", book_section_path(book, section)
end

# 公開側 Section（編集）
crumb :book_section_edit do |book, section|
  parent :book, book
  link "#{section.position}. #{section.heading}：編集", edit_book_section_path(book, section)
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
  parent :pre_code, code
  link "編集", edit_pre_code_path(code)
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

# --- Static pages ---
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

# --- Profile（ユーザープロフィール） ---
crumb :profile do
  parent :root
  link "プロフィール", profile_path
end

crumb :profile_edit do
  parent :profile
  link "編集", edit_profile_path
end

# --- Quizzes（公開） ---
# クイズ一覧
crumb :quizzes do
  parent :root
  link "クイズ一覧", quizzes_path
end

# クイズ詳細（クイズのトップ：セクション一覧など）
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
# --- 応急処置：titleに触らず、IDベースのラベル + params フォールバック ---
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

# セクション結果ページ（result）
# --- 応急処置：params フォールバック ---
crumb :quiz_section_result do |quiz, section|
  parent :quiz_section_public, quiz, section
  qid = (quiz && quiz.respond_to?(:id)) ? quiz.id : params[:quiz_id]
  sid = (section && section.respond_to?(:id)) ? section.id : (params[:section_id] || params[:id])
  link "結果", result_quiz_section_path(qid, sid)
end

# 問題編集（公開側の編集画面はルートに存在。学習用に置いておく）
crumb :quiz_question_edit do |quiz, section, question|
  parent :quiz_question, quiz, section, question
  link "編集", edit_quiz_section_question_path(quiz, section, question)
end

# クイズ空画面（URLが無い想定なのでリンク無しで表記だけ）
crumb :quiz_empty do
  parent :quizzes
  link "空のクイズ", nil
end

# ============================================================
# 管理（Admin）エリア
# ============================================================

# ダッシュボード（管理の起点）
crumb :admin_root do
  parent :root
  link "ダッシュボード", admin_root_path
end

# --- Admin: Users ---
crumb :admin_users do
  parent :admin_root
  link "ユーザー管理", admin_users_path
end

# --- Admin: Books ---
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

# --- Admin: Book Sections ---
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

# --- Admin: PreCodes ---
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

# --- Admin: Tags ---
crumb :admin_tags do
  parent :admin_root
  link "タグ管理", admin_tags_path
end

# --- Admin: Quizzes（作成系） ---
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

# --- Admin: Quiz Sections ---
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

# --- 応急処置：titleに触らず、params[:id] フォールバック ---
crumb :admin_quiz_section_edit do |section|
  parent :admin_quiz_sections
  sid = (section && section.respond_to?(:id)) ? section.id : params[:id]
  link "セクション ##{sid}：編集", edit_admin_quiz_section_path(sid)
end

# --- Admin: Quiz Questions ---
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

# --- 応急処置：question が nil でも params[:id] で表示 ---
crumb :admin_quiz_question_edit do |question|
  parent :admin_quiz_questions
  qid = (question && question.respond_to?(:id)) ? question.id : params[:id]
  link "問題 ##{qid}：編集", edit_admin_quiz_question_path(qid)
end

# --- Admin: Editor Permissions ---
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

# --- 応急処置：perm が nil でも params[:id] で表示 ---
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

# --- Admin: Versions（バージョン管理） ---
crumb :admin_versions do
  parent :admin_root
  link "変更履歴", admin_versions_path
end

crumb :admin_version do |version|
  parent :admin_versions
  link "##{version.id}", admin_version_path(version)
end

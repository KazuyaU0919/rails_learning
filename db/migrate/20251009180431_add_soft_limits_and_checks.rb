class AddSoftLimitsAndChecks < ActiveRecord::Migration[8.0]
  def up
    # ====== string 長さ制限（DBレベル） ======
    change_column :books,          :title, :string, limit: 100
    change_column :quizzes,        :title, :string, limit: 100
    change_column :book_sections,  :heading, :string, limit: 50
    change_column :quiz_sections,  :heading, :string, limit: 100
    change_column :quiz_questions, :choice1, :string, limit: 100
    change_column :quiz_questions, :choice2, :string, limit: 100
    change_column :quiz_questions, :choice3, :string, limit: 100
    change_column :quiz_questions, :choice4, :string, limit: 100
    change_column :users,          :name,  :string, limit: 50
    change_column :users,          :email, :string, limit: 255
    change_column :pre_codes,      :title, :string, limit: 50

    # ====== 数値の上限（CHECK で 0..9999 を担保） ======
    add_check(:books,         "position_range",         "position > 0 AND position <= 9999")
    add_check(:quizzes,       "position_range",         "position > 0 AND position <= 9999")
    add_check(:quiz_sections, "position_range",         "position > 0 AND position <= 9999")
    add_check(:quiz_questions, "position_range",         "position > 0 AND position <= 9999")
    add_check(:book_sections, "position_range",         "position >= 0 AND position <= 9999")

    # ====== text カラムの長さ上限（char_length） ======
    add_check(:books,         "description_len",  "char_length(description) <= 1000")
    add_check(:quizzes,       "description_len",  "char_length(description) <= 1000")
    add_check(:book_sections, "content_len",      "char_length(content) <= 30000")
    add_check(:pre_codes,     "description_len",  "description IS NULL OR char_length(description) <= 2000")
    add_check(:pre_codes,     "body_len",         "char_length(body) <= 5000")
    add_check(:pre_codes,     "hint_len",         "hint IS NULL OR char_length(hint) <= 1000")
    add_check(:pre_codes,     "answer_len",       "answer IS NULL OR char_length(answer) <= 2000")
    add_check(:pre_codes,     "answer_code_len",  "answer_code IS NULL OR char_length(answer_code) <= 2000")
    add_check(:quiz_questions, "question_len",     "char_length(question) <= 2000")
    add_check(:quiz_questions, "explanation_len",  "char_length(explanation) <= 2000")
  end

  def down
    # string limit は戻さず（安全側）。CHECK は削除
    drop_check(:books,         "position_range")
    drop_check(:quizzes,       "position_range")
    drop_check(:quiz_sections, "position_range")
    drop_check(:quiz_questions, "position_range")
    drop_check(:book_sections, "position_range")

    drop_check(:books,         "description_len")
    drop_check(:quizzes,       "description_len")
    drop_check(:book_sections, "content_len")
    drop_check(:pre_codes,     "description_len")
    drop_check(:pre_codes,     "body_len")
    drop_check(:pre_codes,     "hint_len")
    drop_check(:pre_codes,     "answer_len")
    drop_check(:pre_codes,     "answer_code_len")
    drop_check(:quiz_questions, "question_len")
    drop_check(:quiz_questions, "explanation_len")
  end

  private

  def add_check(table, name, expr)
    execute <<~SQL
      ALTER TABLE #{table}
      ADD CONSTRAINT #{table}_#{name}_chk
      CHECK (#{expr})
    SQL
  end

  def drop_check(table, name)
    execute <<~SQL
      ALTER TABLE #{table}
      DROP CONSTRAINT IF EXISTS #{table}_#{name}_chk
    SQL
  end
end

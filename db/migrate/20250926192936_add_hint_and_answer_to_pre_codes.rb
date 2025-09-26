class AddHintAndAnswerToPreCodes < ActiveRecord::Migration[8.0]
  def change
    add_column :pre_codes, :hint,   :text
    add_column :pre_codes, :answer, :text
    add_column :pre_codes, :answer_code, :text
  end
end

class AddLockVersionToEditableModels < ActiveRecord::Migration[8.0]
  def change
    add_column :book_sections,  :lock_version, :integer, null: false, default: 0
    add_column :quiz_questions, :lock_version, :integer, null: false, default: 0
  end
end

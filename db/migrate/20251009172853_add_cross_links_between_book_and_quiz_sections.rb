class AddCrossLinksBetweenBookAndQuizSections < ActiveRecord::Migration[8.0]
  def change
    # book_sections.quiz_section_id（任意／削除時は null）
    add_column :book_sections, :quiz_section_id, :bigint
    add_index  :book_sections, :quiz_section_id
    add_foreign_key :book_sections, :quiz_sections,
                    column: :quiz_section_id, on_delete: :nullify

    # quiz_sections.book_section_id（任意／削除時は null）
    add_column :quiz_sections, :book_section_id, :bigint
    add_index  :quiz_sections, :book_section_id
    add_foreign_key :quiz_sections, :book_sections,
                    column: :book_section_id, on_delete: :nullify
  end
end

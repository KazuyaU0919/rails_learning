# app/helpers/quizzes_helper.rb
module QuizzesHelper
  def choice_label(question, n)
    question.public_send("choice#{n}")
  end
end

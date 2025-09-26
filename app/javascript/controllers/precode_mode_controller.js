// app/javascript/controllers/precode_mode_controller.js
import { Controller } from "@hotwired/stimulus"

// モード切替：通常 / 問題
export default class extends Controller {
  static targets = [
    "toggle", "titleLabel", "descLabel",
    "quizBlock",          // 複数（ヒントブロック／解答ブロック）
    "answerField",        // textarea[name="pre_code[answer]"]
    "answerCodeField"     // textarea[name="pre_code[answer_code]"]
  ]
  static values  = { mode: String } // "normal" | "quiz"

  connect() {
    this.modeValue ||= "normal"
    this.apply()
  }

  switch() {
    this.modeValue = (this.modeValue === "normal") ? "quiz" : "normal"
    this.apply()
  }

  apply() {
    const quiz = this.modeValue === "quiz"

    // ラベル切替
    if (this.hasTitleLabelTarget) this.titleLabelTarget.textContent = quiz ? "問題タイトル" : "登録名"
    if (this.hasDescLabelTarget)  this.descLabelTarget.textContent  = quiz ? "問題文"       : "コードの説明"

    // ヒント／解答ブロックの表示非表示（複数ターゲット）
    if (this.hasQuizBlockTarget) {
      this.quizBlockTargets.forEach(el => el.classList.toggle("hidden", !quiz))
    }

    // answer を問題モード時のみ required・有効にする
    if (this.hasAnswerFieldTarget) {
      this.answerFieldTarget.toggleAttribute("required", quiz)
      this.answerFieldTarget.disabled = !quiz
    }
    // answer_code も問題モード時のみ有効に（必須にはしない）
    if (this.hasAnswerCodeFieldTarget) {
      this.answerCodeFieldTarget.disabled = !quiz
    }

    // トグルボタン表示
    if (this.hasToggleTarget) {
      this.toggleTarget.textContent = quiz ? "通常モードに戻す" : "問題モードにする"
    }
  }
}

// app/javascript/controllers/precode_mode_controller.js
import { Controller } from "@hotwired/stimulus"

// モード切替：通常 / 問題
export default class extends Controller {
  static targets = [
    "toggle", "titleLabel", "descLabel",
    "quizBlock",
    "answerField", "answerCodeField",
    "modeField" // ← hidden の pre_code[quiz_mode]
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

    // ヒント／解答ブロックの表示非表示
    if (this.hasQuizBlockTarget) {
      this.quizBlockTargets.forEach(el => el.classList.toggle("hidden", !quiz))
    }

    // 必須/有効
    if (this.hasAnswerFieldTarget) {
      this.answerFieldTarget.toggleAttribute("required", quiz)
      this.answerFieldTarget.disabled = !quiz
    }
    if (this.hasAnswerCodeFieldTarget) {
      this.answerCodeFieldTarget.disabled = !quiz
    }

    // hidden へ現在モードを反映（"true"/"false"）
    if (this.hasModeFieldTarget) {
      this.modeFieldTarget.value = quiz ? "true" : "false"
    }

    // 表示切替後に autosize に再計算を依頼
    this.element
      .querySelectorAll('[data-controller~="autosize"]')
      .forEach(el => el.dispatchEvent(new Event("autosize:refresh")))

    // トグルボタン表示
    if (this.hasToggleTarget) {
      this.toggleTarget.textContent = quiz ? "通常モードに戻す" : "問題モードにする"
    }
  }
}

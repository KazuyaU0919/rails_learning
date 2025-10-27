// ============================================================
// precode_mode_controller.js
// ------------------------------------------------------------
// 目的：PreCode の入力画面で「通常モード」と「問題モード」を切り替える。
// 用途：フォーム内のラベル文言切替、ヒント／解答ブロックの表示制御、
//       必須制御、hidden フィールドへのモード反映、autosize の再計算など。
// 特徴：Stimulus の targets/values を活用し、UI の一括制御を行う。
// ============================================================

import { Controller } from "@hotwired/stimulus"

// モード切替：normal / quiz
export default class extends Controller {
  // =======================
  // ターゲット・値
  // =======================
  static targets = [
    "toggle", "titleLabel", "descLabel",   // ラベルやトグルボタン
    "quizBlock",                           // 問題モードで表示するブロック（複数対応）
    "answerField", "answerCodeField",      // 必須／enabled 制御
    "modeField"                            // hidden pre_code[quiz_mode] ("true"/"false")
  ]
  static values  = { mode: String }        // "normal" | "quiz"

  // =======================
  // ライフサイクル
  // =======================
  connect() {
    // 値が未設定なら normal を既定にする
    this.modeValue ||= "normal"
    this.apply()
  }

  // =======================
  // パブリック API
  // =======================
  // トグルボタンから呼ぶ：normal <-> quiz
  switch() {
    this.modeValue = (this.modeValue === "normal") ? "quiz" : "normal"
    this.apply()
  }

  // =======================
  // 表示適用（中心処理）
  // =======================
  apply() {
    const quiz = this.modeValue === "quiz"

    // ---- ラベル文言の切替 ----
    if (this.hasTitleLabelTarget) this.titleLabelTarget.textContent = quiz ? "問題タイトル" : "登録名"
    if (this.hasDescLabelTarget)  this.descLabelTarget.textContent  = quiz ? "問題文"       : "コードの説明"

    // ---- ヒント／解答ブロックの表示切替（複数対応）----
    if (this.hasQuizBlockTarget) {
      this.quizBlockTargets.forEach(el => el.classList.toggle("hidden", !quiz))
    }

    // ---- 必須／有効制御 ----
    if (this.hasAnswerFieldTarget) {
      this.answerFieldTarget.toggleAttribute("required", quiz)
      this.answerFieldTarget.disabled = !quiz
    }
    if (this.hasAnswerCodeFieldTarget) {
      this.answerCodeFieldTarget.disabled = !quiz
    }

    // ---- hidden へ現在モードを反映 ----
    if (this.hasModeFieldTarget) {
      this.modeFieldTarget.value = quiz ? "true" : "false"
    }

    // ---- autosize コントローラへ再計算依頼 ----
    // 表示切替で高さが崩れないよう、対象へカスタムイベントを送る
    this.element
      .querySelectorAll('[data-controller~="autosize"]')
      .forEach(el => el.dispatchEvent(new Event("autosize:refresh")))

    // ---- トグルボタンの文言 ----
    if (this.hasToggleTarget) {
      this.toggleTarget.textContent = quiz ? "通常モードに戻す" : "問題モードにする"
    }
  }
}

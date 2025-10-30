// ============================================================
// reveal_controller.js
// ------------------------------------------------------------
// 目的：指定要素（contentTargets）を show/hide する簡易トグル。
// 用途：説明の折りたたみ、補足情報の表示などに。
// 特徴：
//  - 初期は hidden（CSS 側）想定
//  - 表示状態を shownValue(Boolean) で保持
//  - ボタン文言（open/close）は値で上書き可能
// ============================================================

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  // =======================
  // ターゲット・値
  // =======================
  static targets = ["button", "content"]
  static values  = {
    shown: Boolean,
    openLabel: String,   // 例: "🔰 初めての方へ"
    closeLabel: String   // 例: "🔰 説明を閉じる"
  }

  // =======================
  // ライフサイクル
  // =======================
  connect() {
    // 指定がなければ閉じた状態から開始
    this.shownValue ||= false
    this.apply()
  }

  // =======================
  // パブリック API
  // =======================
  toggle() {
    this.shownValue = !this.shownValue
    this.apply()
  }

  // =======================
  // 表示適用
  // =======================
  apply() {
    // ---- content の表示/非表示 ----
    this.contentTargets.forEach(el => el.classList.toggle("hidden", !this.shownValue))

    // ---- ボタン文言（指定があれば上書き）----
    if (this.hasButtonTarget) {
      const open  = this.hasOpenLabelValue  ? this.openLabelValue  : "表示する"
      const close = this.hasCloseLabelValue ? this.closeLabelValue : "非表示にする"
      this.buttonTarget.textContent = this.shownValue ? close : open
    }
  }
}

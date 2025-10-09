// app/javascript/controllers/reveal_controller.js
import { Controller } from "@hotwired/stimulus"

// 指定要素を show/hide。初期は hidden（CSSで隠す）想定。
export default class extends Controller {
  static targets = ["button", "content"]
  static values  = {
    shown: Boolean,
    openLabel: String,   // 例: "🔰 初めての方へ"
    closeLabel: String   // 例: "🔰 説明を閉じる"
  }

  connect() {
    this.shownValue ||= false
    this.apply()
  }

  toggle() {
    this.shownValue = !this.shownValue
    this.apply()
  }

  apply() {
    // content の表示/非表示
    this.contentTargets.forEach(el => el.classList.toggle("hidden", !this.shownValue))

    // ボタン表示文言：指定があればそちらを優先
    if (this.hasButtonTarget) {
      const open = this.hasOpenLabelValue ? this.openLabelValue : "表示する"
      const close = this.hasCloseLabelValue ? this.closeLabelValue : "非表示にする"
      this.buttonTarget.textContent = this.shownValue ? close : open
    }
  }
}

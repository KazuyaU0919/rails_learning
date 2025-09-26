// app/javascript/controllers/reveal_controller.js
import { Controller } from "@hotwired/stimulus"

// 指定要素を show/hide。初期は hidden（CSSで隠す）想定。
export default class extends Controller {
  static targets = ["button", "content"]
  static values  = { shown: Boolean }

  connect() {
    this.shownValue ||= false
    this.apply()
  }

  toggle() {
    this.shownValue = !this.shownValue
    this.apply()
  }

  apply() {
    this.contentTargets.forEach(el => el.classList.toggle("hidden", !this.shownValue))
    if (this.hasButtonTarget) this.buttonTarget.textContent = this.shownValue ? "非表示にする" : "表示する"
  }
}

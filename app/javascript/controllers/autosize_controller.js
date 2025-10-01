// app/javascript/controllers/autosize_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["field", "counter"]
  static values  = { minRows: Number, maxLength: Number }

  connect() {
    // 同一要素に controller と target を同居させてもOK
    this._onInput   = () => { this.grow(); this.updateCounter() }
    this._onRefresh = () => { this.grow(); this.updateCounter() }

    this.fieldTarget.addEventListener("input", this._onInput)
    // precode-mode 側から送るカスタムイベント
    this.element.addEventListener("autosize:refresh", this._onRefresh)

    this.grow()
    this.updateCounter()
  }

  disconnect() {
    this.fieldTarget.removeEventListener("input", this._onInput)
    this.element.removeEventListener("autosize:refresh", this._onRefresh)
  }

  grow() {
    const ta = this.fieldTarget
    // 非表示（display:none）の時は正しく測れないのでスキップ
    if (!ta || ta.offsetParent === null) return

    // rows の初期値（または minRows）を基準にして高さを決める
    const baseRows = this.hasMinRowsValue
      ? this.minRowsValue
      : parseInt(ta.getAttribute("rows") || "2", 10)

    // CSSの高さを直接調整（スクロールバーを出さない）
    ta.style.overflowY = "hidden"
    ta.style.height = "auto"
    // 1行相当の高さに rows を合わせた上で scrollHeight を採用
    ta.rows = baseRows
    ta.style.height = `${ta.scrollHeight}px`
  }

  updateCounter() {
    if (!this.hasMaxLengthValue || this.counterTargets.length === 0) return
    const remain = Math.max(0, this.maxLengthValue - this.fieldTarget.value.length)
    this.counterTargets.forEach(el => { el.textContent = remain })
  }
}

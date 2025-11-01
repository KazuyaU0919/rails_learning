// ============================================================
// autosize_controller.js
// ------------------------------------------------------------
// <textarea> の高さを内容に合わせて自動調整し、
// 文字数カウンタ（残り文字数）の更新も行う Stimulus コントローラ。
// - 非表示状態(display:none)では計測できないため、その場合は何もしない
// - 同一要素に controller/target を同居させても動作する設計
// - 外部から "autosize:refresh" カスタムイベントを受けても再計測できる
// ============================================================

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  // =======================
  // Targets / Values
  // =======================
  static targets = ["field", "counter"]
  static values  = {
    minRows: Number,   // 最小行数（未指定なら <textarea rows> を採用）
    maxLength: Number  // カウンタ計算用の最大文字数
  }

  // =======================
  // ライフサイクル
  // =======================
  connect() {
    // 入力時に高さを再計測＆カウンタ更新
    this._onInput   = () => { this.grow(); this.updateCounter() }
    // 外部（別コントローラ等）から再計測を指示できるようにする
    this._onRefresh = () => { this.grow(); this.updateCounter() }

    this.fieldTarget.addEventListener("input", this._onInput)
    this.element.addEventListener("autosize:refresh", this._onRefresh)

    // 初期表示直後にも高さとカウンタを整える
    this.grow()
    this.updateCounter()
  }

  disconnect() {
    this.fieldTarget.removeEventListener("input", this._onInput)
    this.element.removeEventListener("autosize:refresh", this._onRefresh)
  }

  // =======================
  // イベントハンドラ相当の公開メソッド
  // =======================
  // 高さを内容に合わせて再計算
  grow() {
    const ta = this.fieldTarget
    // 非表示（display:none）の時は正しく scrollHeight を取得できないためスキップ
    if (!ta || ta.offsetParent === null) return

    // 基準行数（minRows があれば優先、なければ rows 属性）
    const baseRows = this.hasMinRowsValue
      ? this.minRowsValue
      : parseInt(ta.getAttribute("rows") || "2", 10)

    // スクロールバーを出さないようにしてから高さをオートに戻す
    ta.style.overflowY = "hidden"
    ta.style.height = "auto"

    // まず rows を基準行数に設定し、次に scrollHeight を高さとして採用
    ta.rows = baseRows
    ta.style.height = `${ta.scrollHeight}px`
  }

  // 残り文字数カウンタを更新（maxLength 未指定 or counter ターゲットなしなら何もしない）
  updateCounter() {
    if (!this.hasMaxLengthValue || this.counterTargets.length === 0) return
    const remain = Math.max(0, this.maxLengthValue - this.fieldTarget.value.length)
    this.counterTargets.forEach(el => { el.textContent = remain })
  }
}

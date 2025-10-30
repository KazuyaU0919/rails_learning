// ============================================================
// modal_controller.js
// ------------------------------------------------------------
// シンプルなモーダル表示用コントローラ。
// - open()/close() で表示・非表示
// - ESC キーで閉じる
// - backdrop（背景クリック）で閉じる（外側クリック判定）
// - data-autofocus 要素 or 最初のフォーカス可能要素に初期フォーカス
// ============================================================

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  // =======================
  // ターゲット
  // =======================
  static targets = ["container", "panel", "backdrop"]

  // =======================
  // ライフサイクル
  // =======================
  connect() {
    // ESC キーで閉じる
    this._onKeydown = (e) => { if (e.key === "Escape") this.close() }
  }

  // =======================
  // パブリック API
  // =======================

  // 開く：スクロールロック・初期フォーカス設定
  open() {
    this.containerTarget.classList.remove("hidden")
    document.body.classList.add("overflow-hidden")
    document.addEventListener("keydown", this._onKeydown)

    // 初期フォーカス：data-autofocus > フォーカス可能要素の順
    const f = this.panelTarget.querySelector("[data-autofocus]") ||
              this.panelTarget.querySelector("a,button,input,select,textarea,[tabindex]:not([tabindex='-1'])")
    if (f) f.focus()
  }

  // 閉じる：スクロールロック解除・イベント解除
  close() {
    this.containerTarget.classList.add("hidden")
    document.body.classList.remove("overflow-hidden")
    document.removeEventListener("keydown", this._onKeydown)
  }

  // 背景クリックで閉じる（内側クリックは無視）
  backdrop(e) {
    if (e.target === this.backdropTarget) this.close()
  }
}

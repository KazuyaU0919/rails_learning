// ============================================================
// loading_controller.js
// ------------------------------------------------------------
// 全画面ローディングオーバーレイ表示用の Stimulus コントローラ。
// 目的：API 実行など時間のかかる処理を UI 的にカバーし、UX を改善。
// 提供 API：
//   - await this.start({ timeoutMs?, delayMs? }) => started:boolean
//   - await this.stop()
//   - await this.withOverlay(async (signal)=>{ ... })  // ラッパユーティリティ
//
// 特徴：
//   - 「表示遅延」(デフォ 200ms) でチラつき防止
//   - 「タイムアウト」(デフォ 15s) で固まる UI を回避（AbortSignal 発火）
//   - 簡易フォーカストラップでアクセシビリティ配慮
//   - 実行前にフォーカス要素を記憶 → 終了時に復帰
// ============================================================

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  // =======================
  // 値（パラメータ）
  // =======================
  static values = {
    delayMs: Number,   // 表示遅延（ms）: 既定 200
    timeoutMs: Number  // タイムアウト（ms）: 既定 15000
  }

  // =======================
  // ライフサイクル
  // =======================
  connect() {
    // 実行状態の一時変数
    this.overlay = null
    this.abortController = null
    this._delayTimer = null
    this._timeoutTimer = null
    this._lastFocused = null
  }

  // =======================
  // パブリック API
  // =======================

  /**
   * 任意の非同期処理をローディングオーバーレイでラップ実行
   * @param {(signal:AbortSignal)=>Promise<any>} run
   */
  async withOverlay(run) {
    const started = await this.start()
    try {
      const signal = this.abortController?.signal
      return await run(signal)
    } finally {
      if (started) await this.stop()
    }
  }

  /**
   * オーバーレイ表示を開始
   * @param {{timeoutMs?:number, delayMs?:number}} opts
   * @returns {Promise<boolean>} すでに表示中なら false
   */
  async start(opts = {}) {
    if (this.overlay) return false

    const delay   = (opts.delayMs   ?? this.delayMsValue)   || 200
    const timeout = (opts.timeoutMs ?? this.timeoutMsValue) || 15000

    // フォーカス復帰用に記憶
    this._lastFocused = document.activeElement

    // AbortSignal を呼び出し側に提供
    this.abortController = new AbortController()

    // 1) 表示遅延（チラつき防止）
    this._delayTimer = setTimeout(() => this.#showOverlay(), delay)

    // 2) タイムアウトで自動 abort
    this._timeoutTimer = setTimeout(() => {
      try { this.abortController?.abort("timeout") } catch {}
      this.#toast("通信がタイムアウトしました")
      this.stop()
      // （任意）analytics: loading_timeout
    }, timeout)

    // （任意）analytics: loading_start
    return true
  }

  /**
   * オーバーレイ終了
   * - DOM 反映後 100ms でフェードアウト
   */
  async stop() {
    clearTimeout(this._delayTimer)
    clearTimeout(this._timeoutTimer)
    this._delayTimer = this._timeoutTimer = null

    // Signal 解放
    this.abortController = null

    if (!this.overlay) return

    // フェードアウト → DOM 破棄
    this.overlay.classList.add("opacity-0")
    await new Promise(r => setTimeout(r, 100))
    this.overlay.remove()
    this.overlay = null

    // フォーカス復帰
    if (this._lastFocused && typeof this._lastFocused.focus === "function") {
      try { this._lastFocused.focus() } catch {}
    }
    this._lastFocused = null
  }

  // =======================
  // 内部実装
  // =======================

  // オーバーレイ DOM を生成して表示
  #showOverlay() {
    if (this.overlay) return

    const el = document.createElement("div")
    // 初期は透明→次フレームで不透明にしてフェードイン
    el.className =
      "fixed inset-0 z-50 bg-black/40 flex items-center justify-center " +
      "transition-opacity duration-100 opacity-0"

    el.innerHTML = `
      <div role="dialog" aria-modal="true" class="flex flex-col items-center gap-3 outline-none">
        <div class="animate-spin rounded-full h-10 w-10 border-4 border-white/60 border-t-transparent"></div>
        <div role="status" aria-live="polite" class="text-white text-sm">Loading...</div>
      </div>
      <button class="sr-only" aria-hidden="true">trap-start</button>
      <button class="sr-only" aria-hidden="true">trap-end</button>
    `

    document.body.appendChild(el)
    this.overlay = el

    // フェードイン
    requestAnimationFrame(() => el.classList.remove("opacity-0"))

    // 簡易フォーカストラップ
    this.#trapFocus(el)
  }

  // オーバーレイ内からフォーカスが外へ出ないようにする簡易実装
  #trapFocus(root) {
    const focusables = () => {
      return Array.from(
        root.querySelectorAll(
          'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
        )
      ).filter(el => !el.hasAttribute("disabled") && !el.getAttribute("aria-hidden"))
    }

    const onKeydown = (e) => {
      if (e.key !== "Tab") return
      const list = focusables()
      if (list.length === 0) return e.preventDefault()
      const first = list[0], last = list[list.length - 1]
      if (e.shiftKey && document.activeElement === first) {
        last.focus(); e.preventDefault()
      } else if (!e.shiftKey && document.activeElement === last) {
        first.focus(); e.preventDefault()
      }
    }

    root.addEventListener("keydown", onKeydown)

    // 初期フォーカス（最初のフォーカス可能要素へ）
    const first = focusables()[0]
    if (first) first.focus()
  }

  // シンプルなトースト通知（2秒で自動消滅）
  #toast(message) {
    const n = document.createElement("div")
    n.className =
      "fixed bottom-4 left-1/2 -translate-x-1/2 z-[60] " +
      "bg-black/80 text-white text-sm px-3 py-2 rounded"
    n.textContent = message
    document.body.appendChild(n)
    setTimeout(() => n.remove(), 2000)
  }
}

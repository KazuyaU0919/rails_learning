import { Controller } from "@hotwired/stimulus"

// 全画面ローディングオーバーレイ
// API:
//   await this.start({ timeoutMs?: number, delayMs?: number }) => started:boolean
//   await this.stop()
//   await this.withOverlay(async (signal)=>{ ... })  // 便利ラッパ
export default class extends Controller {
  static values = {
    delayMs: Number,     // 表示遅延（既定 200ms）
    timeoutMs: Number    // タイムアウト（既定 15000ms）
  }

  connect() {
    this.overlay = null
    this.abortController = null
    this._delayTimer = null
    this._timeoutTimer = null
    this._lastFocused = null
  }

  // 実行をオーバーレイでラップ
  async withOverlay(run) {
    const started = await this.start()
    try {
      const signal = this.abortController?.signal
      return await run(signal)
    } finally {
      if (started) await this.stop()
    }
  }

  // オーバーレイ開始
  async start(opts = {}) {
    if (this.overlay) return false

    const delay = (opts.delayMs ?? this.delayMsValue) || 200
    const timeout = (opts.timeoutMs ?? this.timeoutMsValue) || 15000

    this._lastFocused = document.activeElement
    this.abortController = new AbortController()

    // 200ms遅延表示（チラつき防止）
    this._delayTimer = setTimeout(() => this.#showOverlay(), delay)

    // 15s タイムアウト
    this._timeoutTimer = setTimeout(() => {
      try { this.abortController?.abort("timeout") } catch {}
      this.#toast("通信がタイムアウトしました")
      this.stop()
      // （任意）GA: loading_timeout
    }, timeout)

    // （任意）GA: loading_start
    return true
  }

  // オーバーレイ終了（DOM反映→100ms後にフェードアウト）
  async stop() {
    clearTimeout(this._delayTimer)
    clearTimeout(this._timeoutTimer)
    this._delayTimer = this._timeoutTimer = null

    this.abortController = null

    if (!this.overlay) return

    // フェードアウト
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

  // ===================== 内部実装 =====================

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

    // フォーカストラップ（Tabが外へ出ない簡易版）
    this.#trapFocus(el)
  }

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
    // 初期フォーカス
    const first = focusables()[0]
    if (first) first.focus()
  }

  #toast(message) {
    // シンプルトースト（2秒で自動消滅）
    const n = document.createElement("div")
    n.className =
      "fixed bottom-4 left-1/2 -translate-x-1/2 z-[60] " +
      "bg-black/80 text-white text-sm px-3 py-2 rounded"
    n.textContent = message
    document.body.appendChild(n)
    setTimeout(() => n.remove(), 2000)
  }
}

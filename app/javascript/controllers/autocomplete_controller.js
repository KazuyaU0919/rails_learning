// ============================================================
// autocomplete_controller.js
// ------------------------------------------------------------
// 目的：検索フォームにオートコンプリートを提供する Stimulus Controller。
// 概要：
//   - ユーザー入力を 200ms デバウンスして /search/suggest にアクセス
//   - 1秒あたり 5 回までのレート制限（クライアント側）
//   - 60 秒のメモリキャッシュで重複リクエストを削減
//   - キーボード操作：↓/↑ で選択、Enter で遷移、Esc でクローズ
//   - フォーカス/ブラーの扱い（クリック取りこぼし防止）
//   - A11y：listbox/option の ARIA を最低限付与
//
// 想定マークアップ：
//   <div data-controller="autocomplete"
//        data-autocomplete-list-url-value="/pre_codes"
//        data-autocomplete-sort-value="popular">
//     <input data-autocomplete-target="input" ...>
//     <div   data-autocomplete-target="panel" class="hidden"></div>
//   </div>
//
// セキュリティ補足：
//   - 候補の `highlighted` はサーバ側で安全な HTML を生成している前提。
//     受け取った HTML を innerHTML で描画しているため、サーバ側で XSS 対策必須。
//   - 本コントローラはユーザー入力をそのまま fetch クエリに載せるが、
//     URLSearchParams/encodeURIComponent を利用しており、意図しないクエリ分解を防止。
// ============================================================

import { Controller } from "@hotwired/stimulus"

// =======================
// 構成パラメータ（調整用）
// =======================
const DEBOUNCE_MS   = 200          // 入力からリクエストまでの待機
const MAX_RPS       = 5            // 1秒あたりの最大発行回数（Rate Limit）
const CACHE_TTL_MS  = 60_000       // メモリキャッシュの寿命（60秒）

export default class extends Controller {
  // =======================
  // ターゲット / 値（Stimulus）
  // =======================
  static targets = ["input", "panel"]
  static values = {
    listUrl: String, // 一覧ページのベースURL（例：/pre_codes）
    sort:   String   // 現在の sort 値（一覧遷移時に維持）
  }

  // =======================
  // ライフサイクル
  // =======================
  connect() {
    // ---- 内部状態（インスタンス変数） ----
    this._cache       = new Map() // q -> { ts: Number, items: Array }
    this._timer       = null      // デバウンス用
    this._activeIndex = -1        // listbox の選択インデックス
    this._lastTs      = []        // Rate Limit 用：直近1秒のタイムスタンプ配列

    this._bindEvents()

    // パネル開時に Enter でフォーム送信されるのを抑止（候補決定を優先）
    this.formEl = this.inputTarget.closest("form")
    if (this.formEl) {
      this._formSubmitHandler = (e) => {
        const open = !this.panelTarget.classList.contains("hidden")
        if (open) e.preventDefault()
      }
      this.formEl.addEventListener("submit", this._formSubmitHandler)
    }
  }

  disconnect() {
    this._unbindEvents()
    if (this.formEl) this.formEl.removeEventListener("submit", this._formSubmitHandler)
  }

  // =======================
  // イベントバインド / 解除
  // =======================
  _bindEvents() {
    // 入力欄のキー操作：候補のナビゲーションや決定に利用
    this.keydownHandler = (e) => this.onKeydown(e)
    this.inputTarget.addEventListener("keydown", this.keydownHandler)
  }

  _unbindEvents() {
    this.inputTarget.removeEventListener("keydown", this.keydownHandler)
  }

  // =======================
  // 入力・フォーカス系ハンドラ
  // =======================
  // 入力 → デバウンス → サジェスト取得
  onInput() {
    clearTimeout(this._timer)
    this._timer = setTimeout(() => this.fetchSuggest(), DEBOUNCE_MS)
  }

  // 空でなければフォーカス時に即サジェスト（既存値を活かす）
  onFocus() {
    if (this.inputTarget.value.trim() !== "") this.fetchSuggest()
  }

  // クリック選択が onBlur より後に来ることがあるため、少し遅らせて閉じる
  onBlur() {
    setTimeout(() => this.hidePanel(), 120)
  }

  // =======================
  // キーボード操作（上下/Enter/Esc）
  // =======================
  onKeydown(e) {
    const open = !this.panelTarget.classList.contains("hidden")

    // パネルが閉じていて ↓/↑ が来たら、まずサジェストを開く
    if (!open && (e.key === "ArrowDown" || e.key === "ArrowUp")) {
      this.fetchSuggest()
      return
    }
    if (!open) return

    const items = this.panelTarget.querySelectorAll("[role='option']")

    if (e.key === "ArrowDown") {
      e.preventDefault()
      this._activeIndex = Math.min(items.length - 1, this._activeIndex + 1)
      this._applyActive(items)
    } else if (e.key === "ArrowUp") {
      e.preventDefault()
      this._activeIndex = Math.max(0, this._activeIndex - 1)
      this._applyActive(items)
    } else if (e.key === "Enter") {
      e.preventDefault()
      this._handleEnter(items)
    } else if (e.key === "Escape") {
      e.preventDefault()
      this.hidePanel()
    }
  }

  // Enter 確定時の処理（選択候補 or そのまま検索）
  _handleEnter(items) {
    if (this._activeIndex < 0) this._activeIndex = 0
    const selected = items[this._activeIndex]

    if (selected) {
      const idx    = Number(selected.dataset.index)
      const chosen = this._lastItems?.[idx]
      const q      = chosen?.query || this.inputTarget.value.trim()
      this.inputTarget.value = q
      this.navigateWithQuery(q)
    } else {
      this.navigateWithQuery(this.inputTarget.value.trim())
    }
  }

  // 見た目のアクティブ状態を反映＋スクロール追従
  _applyActive(items) {
    items.forEach(el => el.classList.remove("bg-slate-100"))
    if (this._activeIndex >= 0 && items[this._activeIndex]) {
      items[this._activeIndex].classList.add("bg-slate-100")
      items[this._activeIndex].scrollIntoView({ block: "nearest" })
    }
  }

  // =======================
  // レート制限（単純なクライアント側 RPS 制御）
  // =======================
  rateLimited() {
    const now = Date.now()
    // 直近 1 秒に入っているものだけ残す
    this._lastTs = this._lastTs.filter(t => now - t < 1000)
    if (this._lastTs.length >= MAX_RPS) return true
    this._lastTs.push(now)
    return false
  }

  // =======================
  // サジェスト取得（キャッシュ→fetch）
  // =======================
  async fetchSuggest() {
    const q = this.inputTarget.value.trim()
    if (q === "") { this.hidePanel(); return }
    if (this.rateLimited()) return

    // ---- キャッシュ（同一クエリの短時間再取得を回避）----
    const cached = this._cache.get(q)
    const now    = Date.now()
    if (cached && (now - cached.ts) < CACHE_TTL_MS) {
      this.render(cached.items, q)
      return
    }

    // ---- fetch 本体 ----
    try {
      const res = await fetch(`/search/suggest?q=${encodeURIComponent(q)}`, {
        headers:     { "Accept": "application/json" },
        credentials: "same-origin"
      })
      if (!res.ok) throw new Error("bad status")

      const json = await res.json()
      const items = json.items || []
      this._cache.set(q, { ts: now, items })
      this.render(items, q)
    } catch {
      this.renderError()
    }
  }

  // =======================
  // レンダリング（候補 or エラー）
  // =======================
  render(items, q) {
    this._lastItems   = items
    this._activeIndex = 0

    if (!items.length) {
      // 候補なし
      this.panelTarget.innerHTML =
        `<div class="p-2 text-sm text-slate-500">候補はありません</div>`
      this.showPanel()
      return
    }

    // 候補の行を構築（type バッジ + サーバ生成の highlighted HTML）
    const rows = items.map((it, idx) => `
      <div role="option" data-index="${idx}"
           class="px-3 py-2 text-sm cursor-pointer flex gap-2 items-start hover:bg-slate-100"
           aria-selected="false">
        <span class="shrink-0 mt-0.5 text-xs px-1.5 py-0.5 rounded bg-slate-200 text-slate-700">
          ${it.type === "title" ? "Title" : "Desc"}
        </span>
        <span class="grow leading-5">${it.highlighted}</span>
      </div>
    `).join("")

    this.panelTarget.innerHTML = rows
    this._bindItemEvents(items, q)
    this.showPanel()
    this._applyActive(this.panelTarget.querySelectorAll("[role='option']"))
  }

  renderError() {
    this.panelTarget.innerHTML =
      `<div class="p-2 text-sm text-red-600">通信エラー</div>`
    this.showPanel()
  }

  // 各候補行にマウス操作のイベントを付与（hoverでアクティブ移動／clickで遷移）
  _bindItemEvents(items, q) {
    this.panelTarget.querySelectorAll("[role='option']").forEach((el, idx) => {
      el.addEventListener("mouseenter", () => {
        this._activeIndex = idx
        this._applyActive(this.panelTarget.querySelectorAll("[role='option']"))
      })

      // mousedown にしているのは、blur → click の順序ズレで遷移が失敗しないようにするため
      el.addEventListener("mousedown", (e) => {
        e.preventDefault()
        this.inputTarget.value = items[idx].query
        this.navigateWithQuery(items[idx].query || q)
      })
    })
  }

  // =======================
  // パネル表示制御（A11y最低限）
  // =======================
  showPanel() {
    this.panelTarget.classList.remove("hidden")
    this.panelTarget.setAttribute("role", "listbox")
  }

  hidePanel() {
    this.panelTarget.classList.add("hidden")
    this.panelTarget.removeAttribute("role")
  }

  // =======================
  // 一覧ページへ遷移
  // =======================
  // 例：/pre_codes?q[title_or_description_cont]=検索語&sort=...&page=1
  navigateWithQuery(q) {
    if (!q) return
    const params = new URLSearchParams()
    params.set("q[title_or_description_cont]", q)
    if (this.hasSortValue && this.sortValue) params.set("sort", this.sortValue)
    params.set("page", "1")

    const to = `${this.listUrlValue}?${params.toString()}`
    window.location.assign(to)
  }
}

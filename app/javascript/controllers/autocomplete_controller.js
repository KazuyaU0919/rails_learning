// app/javascript/controllers/autocomplete_controller.js
// 検索入力にアタッチして、200ms デバウンス → /search/suggest を叩く。
// 1秒5回のレート制限、同一クエリ60秒メモリキャッシュ、矢印/Enter/ESC 対応。

import { Controller } from "@hotwired/stimulus"

const DEBOUNCE_MS = 200
const MAX_RPS = 5          // 1秒あたり最大5回
const CACHE_TTL_MS = 60_000

export default class extends Controller {
  static targets = ["input", "panel"]
  static values = {
    listUrl: String,   // 例：/code_libraries か /pre_codes
    sort: String       // 現在の sort 値（維持する）
  }

  connect() {
    this._cache = new Map() // q -> {ts, items}
    this._timer = null
    this._activeIndex = -1
    this._lastTs = []
    this._bindEvents()
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

  _bindEvents() {
    this.keydownHandler = (e) => this.onKeydown(e)
    this.inputTarget.addEventListener("keydown", this.keydownHandler)
  }

  _unbindEvents() {
    this.inputTarget.removeEventListener("keydown", this.keydownHandler)
  }

  // input -> debounce
  onInput() {
    clearTimeout(this._timer)
    this._timer = setTimeout(() => this.fetchSuggest(), DEBOUNCE_MS)
  }

  onFocus() {
    if (this.inputTarget.value.trim() !== "") this.fetchSuggest()
  }

  onBlur(e) {
    // 少し遅らせて click を拾わせる
    setTimeout(() => this.hidePanel(), 120)
  }

  onKeydown(e) {
    const open = !this.panelTarget.classList.contains("hidden")
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
      if (this._activeIndex < 0) this._activeIndex = 0
      if (items[this._activeIndex]) {
        // click だと onBlur タイミング次第で不安定なので直接遷移
        const list = this.panelTarget.querySelectorAll("[role='option']")
        const selected = list[this._activeIndex]
        if (selected) {
          const idx = Number(selected.dataset.index)
          const chosen = this._lastItems?.[idx] || null
          const q = chosen?.query || this.inputTarget.value.trim()
          this.inputTarget.value = q
          this.navigateWithQuery(q)
        }
      } else {
        // 候補がなくても通常検索に遷移
        this.navigateWithQuery(this.inputTarget.value.trim())
      }
    } else if (e.key === "Escape") {
      e.preventDefault()
      this.hidePanel()
    }
  }

  _applyActive(items) {
    items.forEach(el => el.classList.remove("bg-slate-100"))
    if (this._activeIndex >= 0 && items[this._activeIndex]) {
      items[this._activeIndex].classList.add("bg-slate-100")
      items[this._activeIndex].scrollIntoView({ block: "nearest" })
    }
  }

  rateLimited() {
    const now = Date.now()
    this._lastTs = this._lastTs.filter(t => now - t < 1000)
    if (this._lastTs.length >= MAX_RPS) return true
    this._lastTs.push(now)
    return false
  }

  async fetchSuggest() {
    const q = this.inputTarget.value.trim()
    if (q === "") { this.hidePanel(); return }

    if (this.rateLimited()) return

    // cache
    const cached = this._cache.get(q)
    const now = Date.now()
    if (cached && (now - cached.ts) < CACHE_TTL_MS) {
      this.render(cached.items, q)
      return
    }

    try {
      const res = await fetch(`/search/suggest?q=${encodeURIComponent(q)}`, {
        headers: { "Accept": "application/json" },
        credentials: "same-origin"
      })
      if (!res.ok) throw new Error("bad status")
      const json = await res.json()
      this._cache.set(q, { ts: now, items: json.items || [] })
      this.render(json.items || [], q)
    } catch (e) {
      this.renderError()
    }
  }

  render(items, q) {
    this._lastItems = items
    this._activeIndex = 0
    if (!items.length) {
      this.panelTarget.innerHTML = `
        <div class="p-2 text-sm text-slate-500">候補はありません</div>
      `
      this.showPanel()
      return
    }

    const rows = items.map((it, idx) => {
      const badge = it.type === "title" ? "Title" : "Desc"
      return `
        <div role="option" data-index="${idx}"
             class="px-3 py-2 text-sm cursor-pointer flex gap-2 items-start hover:bg-slate-100"
             aria-selected="false">
          <span class="shrink-0 mt-0.5 text-xs px-1.5 py-0.5 rounded bg-slate-200 text-slate-700">${badge}</span>
          <span class="grow leading-5">${it.highlighted}</span>
        </div>`
    }).join("")

    this.panelTarget.innerHTML = rows
    this.panelTarget.querySelectorAll("[role='option']").forEach((el, idx) => {
      el.addEventListener("mouseenter", () => {
        this._activeIndex = idx
        this._applyActive(this.panelTarget.querySelectorAll("[role='option']"))
      })

      el.addEventListener("mousedown", (e) => {
        e.preventDefault()
        this.inputTarget.value = items[idx].query
        this.navigateWithQuery(items[idx].query || q)
      })
    })
    this.showPanel()
    this._applyActive(this.panelTarget.querySelectorAll("[role='option']"))
  }

  renderError() {
    this.panelTarget.innerHTML = `
      <div class="p-2 text-sm text-red-600">通信エラー</div>
    `
    this.showPanel()
  }

  showPanel() {
    this.panelTarget.classList.remove("hidden")
    this.panelTarget.setAttribute("role", "listbox")
  }

  hidePanel() {
    this.panelTarget.classList.add("hidden")
    this.panelTarget.removeAttribute("role")
  }

  // 一覧へ遷移：q を渡し、page=1、sort は維持
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

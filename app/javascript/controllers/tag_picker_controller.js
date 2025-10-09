// app/javascript/controllers/tag_picker_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "hiddenInput",   // <input name="tag_names"> or <input name="tags">
    "selectedArea",  // 選択済みピル
    "container",     // モーダル
    "list",          // 一覧
    "query",         // 絞り込み入力
    "newName",       // 新規タグ名
    "createError",   // 新規作成エラー表示
  ]

  static values = {
    fetchUrl: { type: String, default: "/tags/popular.json" },
    max:      { type: Number, default: 10 },      // assign モード時の最大
    mode:     { type: String, default: "assign" } // "assign" or "filter"
  }

  connect() {
    this.selected = new Map() // key: tag.name, value: tag object
    this._loaded = false
    this._syncFromHidden()
    this.renderSelected()
    // 初期表示でも水和して数/色を正しくする（モーダルを開かなくても反映）
    this.fetchAndRender().catch(() => {})
  }

  // ===== モーダル =====
  open() {
    this.containerTarget.classList.remove("hidden")
    document.body.classList.add("overflow-hidden")
    if (!this._loaded) this.fetchAndRender().catch(() => {})
  }

  close() {
    this.containerTarget.classList.add("hidden")
    document.body.classList.remove("overflow-hidden")
  }

  // ===== 取得/描画 =====
  async fetchAndRender(q = "") {
    const url = new URL(this.fetchUrlValue, window.location.origin)
    if (q) url.searchParams.set("q", q)

    const res = await fetch(url.toString(), { headers: { "Accept": "application/json" } })
    const list = await res.json()
    this._loaded = true
    // 水和：取得した一覧で選択済みの色/件数を上書き
    this._hydrateSelected(list)
    this.renderList(list)
    this.renderSelected() // 水和結果をフォーム側にも反映
  }

  queryInput(e) {
    const q = e.target.value.trim()
    this.fetchAndRender(q).catch(() => {})
  }

  renderList(list) {
    this.listTarget.innerHTML = ""
    list.forEach(t => {
      const btn = document.createElement("button")
      btn.type = "button"
      btn.className = "inline-flex items-center gap-1 rounded-full px-2 py-1 text-xs border mr-1 mb-1"
      btn.style = `color:${t.color}; border-color:${t.color}; background:${this._rgbaBg(t.color, 0.12)}`
      btn.innerHTML = `${this._escape(t.name)} <span class="text-[11px] text-slate-500">(${t.taggings_count})</span>`
      btn.addEventListener("click", () => this.toggleTag(t))
      this.listTarget.appendChild(btn)
    })
  }

  // ===== 追加/削除 =====
  toggleTag(tag) {
    if (this.selected.has(tag.name)) {
      this.selected.delete(tag.name)
    } else {
      if (this.modeValue === "assign" && this.maxValue && this.selected.size >= this.maxValue) {
        alert(`タグは最大 ${this.maxValue} 個までです`)
        return
      }
      this.selected.set(tag.name, tag)
    }
    this.renderSelected()
    this._syncHidden()
  }

  renderSelected() {
    this.selectedAreaTarget.innerHTML = ""
    for (const t of this.selected.values()) {
      const pill = document.createElement("span")
      pill.className = "inline-flex items-center gap-1 rounded-full px-2 py-1 text-xs border mr-1 mb-1"
      pill.style = `color:${t.color}; border-color:${t.color}; background:${this._rgbaBg(t.color, 0.12)}`
      pill.innerHTML = `${this._escape(t.name)} <span class="text-[11px] text-slate-500">(${t.taggings_count ?? 0})</span>`

      const x = document.createElement("button")
      x.type = "button"
      x.className = "ml-1 text-slate-500 hover:text-slate-700"
      x.textContent = "×"
      x.addEventListener("click", () => { this.selected.delete(t.name); this.renderSelected(); this._syncHidden() })

      pill.appendChild(x)
      this.selectedAreaTarget.appendChild(pill)
    }
  }

  // ===== 新規タグ作成 =====
  async createTag() {
    const name = this.newNameTarget.value.trim()
    this.createErrorTarget.textContent = ""
    if (!name) return

    try {
      const token = document.querySelector('meta[name="csrf-token"]')?.content
      const res = await fetch("/tags", {
        method: "POST",
        headers: { "Content-Type": "application/json", "X-CSRF-Token": token },
        body: JSON.stringify({ tag: { name } })
      })
      const t = await res.json()
      if (!res.ok) throw new Error(t.error || "作成に失敗しました")

      // 作成直後から選択済みに入れる
      this.selected.set(t.name, t)
      this.renderSelected()
      this._syncHidden()
      this.newNameTarget.value = ""

      // 一覧も更新（未使用も popular に出るようサーバ側を修正済み）
      this._loaded = false
      this.fetchAndRender(this.queryTarget?.value?.trim() || "").catch(() => {})
    } catch (e) {
      this.createErrorTarget.textContent = e.message
    }
  }

  // ===== 内部処理 =====
  _syncHidden() {
    const names = [...this.selected.keys()]
    this.hiddenInputTarget.value = names.join(",")
  }

  _syncFromHidden() {
    const raw = this.hiddenInputTarget.value || ""
    raw.split(",").map(s => s.trim()).filter(Boolean).forEach(n => {
      if (!this.selected.has(n)) {
        // 一旦プレースホルダ（後で fetch で水和）
        this.selected.set(n, { name: n, color: "#6B7280", taggings_count: 0 })
      }
    })
  }

  _hydrateSelected(list) {
    const byName = new Map(list.map(t => [t.name, t]))
    for (const name of this.selected.keys()) {
      const hit = byName.get(name)
      if (hit) this.selected.set(name, hit)
    }
  }

  _escape(s) {
    const div = document.createElement("div")
    div.textContent = s
    return div.innerHTML
  }

  _rgbaBg(hex, a = 0.12) {
    if (!hex) return `rgba(107,114,128,${a})`
    const h = hex.replace("#","")
    const r = parseInt(h.slice(0,2), 16)
    const g = parseInt(h.slice(2,4), 16)
    const b = parseInt(h.slice(4,6), 16)
    return `rgba(${r},${g},${b},${a})`
  }
}

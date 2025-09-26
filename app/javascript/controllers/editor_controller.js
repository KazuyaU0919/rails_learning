// app/javascript/controllers/editor_controller.js
import { Controller } from "@hotwired/stimulus"
import axios from "axios"

import { EditorState, Compartment } from "@codemirror/state"
import { EditorView, lineNumbers } from "@codemirror/view"
import { oneDark } from "@codemirror/theme-one-dark"

// CodeMirror 6 共通言語レイヤ
import { StreamLanguage, syntaxHighlighting, HighlightStyle } from "@codemirror/language"

// Ruby レガシーモード（CM5） → CM6 で包む
import { ruby } from "@codemirror/legacy-modes/mode/ruby"

// ハイライト定義（色とタグ）
import { tags as t } from "@lezer/highlight"

const rubyHighlight = HighlightStyle.define([
  { tag: t.comment,                       color: "#16a34a" },
  { tag: [t.string, t.special(t.string)], color: "#2563eb" },
  { tag: t.number,                        color: "#d97706" },
  { tag: [t.keyword, t.controlKeyword],   color: "#9333ea", fontWeight: "600" },
  { tag: [t.atom, t.regexp],              color: "#0ea5e9" },
  { tag: t.function(t.variableName),      color: "#0284c7" },
])

const rubyLang = StreamLanguage.define(ruby)

const KEY = { code: "editor:code", theme: "editor:theme" }
const SAVE_DELAY = 50

export default class extends Controller {
  static targets = ["mount", "output", "select"]

  connect () {
    this.theme = localStorage.getItem(KEY.theme) === "dark" ? "dark" : "light"
    this.themeCompartment = new Compartment()

    this.state = EditorState.create({
      doc: localStorage.getItem(KEY.code) || "",
      extensions: [
        lineNumbers(),
        rubyLang,
        syntaxHighlighting(rubyHighlight),
        EditorView.updateListener.of(v => {
          if (!v.docChanged) return
          clearTimeout(this._saveTimer)
          this._saveTimer = setTimeout(() => {
            localStorage.setItem(KEY.code, v.state.doc.toString())
          }, SAVE_DELAY)
        }),
        this.themeCompartment.of(this.theme === "dark" ? oneDark : []),
      ],
    })

    this.view = new EditorView({ state: this.state, parent: this.mountTarget })

    // 入力欄コンテナの色をテーマと同期
    this.#applyContainerTheme()

    // loading コントローラ（同じ要素に data-controller="loading" を付与している想定）
    this.loadingCtrl = this.application.getControllerForElementAndIdentifier(this.element, "loading")

    // ===== pre_code_id=... で来たときの自動読込 =====
    const params = new URLSearchParams(window.location.search)
    const pid = params.get("pre_code_id")
    if (pid) {
      this.#loadPreCodeBody(pid)
      // （必要ならクエリを消したい場合は下の2行を使ってください）
      // const url = new URL(window.location)
      // url.searchParams.delete("pre_code_id"); window.history.replaceState({}, "", url)
    }
  }

  disconnect () { this.view?.destroy() }

  async run (event) {
    const btn = event?.currentTarget || this.element.querySelector('[data-action="editor#run"]')
    btn?.setAttribute("disabled", "disabled")
    btn?.setAttribute("aria-disabled", "true")
    this.outputTarget.textContent = "実行中…"

    const perform = async (signal) => {
      const code = this.view.state.doc.toString()
      const config = signal ? { signal } : undefined
      const res = await axios.post("/editor", { code }, config)
      if (res.data.stderr && res.data.stderr.length > 0) {
        this.outputTarget.textContent = res.data.stderr
      } else {
        this.outputTarget.textContent = res.data.stdout
      }
    }

    try {
      if (this.loadingCtrl?.withOverlay) {
        await this.loadingCtrl.withOverlay(async (signal) => {
          await perform(signal)
        })
      } else {
        // フォールバック：ローダー未装着でも動作
        await perform()
      }
    } catch (e) {
      // Abort/ネットワーク/5xx など
      const msg = e?.response?.data?.stderr || (e?.message || e)
      this.outputTarget.textContent = `Error: ${msg}`
    } finally {
      btn?.removeAttribute("disabled")
      btn?.removeAttribute("aria-disabled")
    }
  }

  async changeSelect () {
    const id = this.selectTarget.value
    if (!id) return
    // ===== 共通の読込ロジックを呼ぶように =====
    this.#loadPreCodeBody(id)
  }

  toggleTheme () {
    this.theme = this.theme === "dark" ? "light" : "dark"
    localStorage.setItem(KEY.theme, this.theme)
    this.view.dispatch({
      effects: this.themeCompartment.reconfigure(this.theme === "dark" ? oneDark : [])
    })
    // 入力欄コンテナ全面の色も同時に切替え
    this.#applyContainerTheme()
  }

  // ===== private =====
  #applyContainerTheme () {
    const el = this.mountTarget
    el.classList.remove("bg-white", "text-slate-900")
    el.classList.remove("bg-[#0b0f19]", "text-white") // ダーク時の色
    if (this.theme === "dark") {
      el.classList.add("bg-[#0b0f19]", "text-white")
    } else {
      el.classList.add("bg-white", "text-slate-900")
    }
  }

  // ===== PreCode 本文を読み込んでエディタへ反映する共通関数 =====
  async #loadPreCodeBody (id) {
    try {
      const res  = await axios.get(`/pre_codes/${id}/body`)
      const body = res.data?.body || ""
      this.view.dispatch({ changes: { from: 0, to: this.view.state.doc.length, insert: body } })
      localStorage.setItem(KEY.code, body)
      // セレクトを持っている画面なら、選択状態も同期
      if (this.hasSelectTarget) this.selectTarget.value = id
    } catch (e) {
      this.outputTarget.textContent = `Load Error: ${e}`
    }
  }
}

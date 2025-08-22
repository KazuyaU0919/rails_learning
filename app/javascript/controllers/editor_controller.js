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

// -- ここからはあなたの既存ロジックそのまま --
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

  connect() {
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
  }

  disconnect() { this.view?.destroy() }

  async run(event) {
    const btn = event?.currentTarget || this.element.querySelector('[data-action*="editor#run"]')
    btn?.setAttribute("disabled", "disabled")
    this.outputTarget.textContent = "実行中…"
    try {
      const code = this.view.state.doc.toString()
      const res  = await axios.post("/editor", { code })
      const { status, stdout, stderr, time, memory } = res.data
      this.outputTarget.textContent =
        `Status: ${status}\n` +
        (stdout ? `\n=== stdout ===\n${stdout}` : "") +
        (stderr ? `\n=== stderr ===\n${stderr}` : "") +
        (time || memory ? `\n(time: ${time ?? "-"}s, mem: ${memory ?? "-"}KB)` : "")
    } catch (e) {
      this.outputTarget.textContent = `Error: ${e?.response?.data?.error || e}`
    } finally {
      btn?.removeAttribute("disabled")
    }
  }

  async changeSelect() {
    const id = this.selectTarget.value
    if (!id) return
    try {
      const res  = await axios.get(`/pre_codes/${id}/body`)
      const body = res.data?.body || ""
      this.view.dispatch({ changes: { from: 0, to: this.view.state.doc.length, insert: body } })
      localStorage.setItem(KEY.code, body)
    } catch (e) {
      this.outputTarget.textContent = `Load Error: ${e}`
    }
  }

  toggleTheme() {
    this.theme = this.theme === "dark" ? "light" : "dark"
    localStorage.setItem(KEY.theme, this.theme)
    this.view.dispatch({
      effects: this.themeCompartment.reconfigure(this.theme === "dark" ? oneDark : [])
    })
  }
}

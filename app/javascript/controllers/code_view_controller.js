// app/javascript/controllers/code_view_controller.js
import { Controller } from "@hotwired/stimulus"

import { EditorState, Compartment } from "@codemirror/state"
import { EditorView, lineNumbers } from "@codemirror/view"
import { oneDark } from "@codemirror/theme-one-dark"

import { StreamLanguage, syntaxHighlighting, HighlightStyle } from "@codemirror/language"
import { ruby } from "@codemirror/legacy-modes/mode/ruby"
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

export default class extends Controller {
  static targets = ["mount", "field"]
  static values  = { theme: String } // "light" | "dark"

  connect () {
    this.theme = this.themeValue === "dark" ? "dark" : "light"
    this.themeCompartment = new Compartment()

    this.state = EditorState.create({
      doc: this.fieldTarget.value || "",
      extensions: [
        lineNumbers(),
        rubyLang,
        syntaxHighlighting(rubyHighlight),
        EditorState.readOnly.of(true),
        this.themeCompartment.of(this.theme === "dark" ? oneDark : []),
      ],
    })

    this.view = new EditorView({ state: this.state, parent: this.mountTarget })
    this.#applyContainerTheme()
  }

  disconnect () { this.view?.destroy() }

  // ---- private ----
  #applyContainerTheme () {
    const el = this.mountTarget
    el.classList.remove("bg-white","text-slate-900","bg-[#0b0f19]","text-white")
    if (this.theme === "dark") {
      el.classList.add("bg-[#0b0f19]", "text-white")
    } else {
      el.classList.add("bg-white", "text-slate-900")
    }
  }
}

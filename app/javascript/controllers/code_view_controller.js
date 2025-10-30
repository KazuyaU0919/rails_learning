// ============================================================
// code_view_controller.js
// ------------------------------------------------------------
// CodeMirror を使ってコードを「閲覧専用」で表示する Stimulus コントローラ。
// 主な用途：PreCode詳細画面やクイズ回答のコード例など。
// - 読み取り専用のエディタとして CodeMirror を初期化
// - 外部から set() で表示内容を差し替え可能
// - themeValue に応じてライト/ダーク切り替え
// ============================================================

import { Controller } from "@hotwired/stimulus"

import { EditorState, Compartment } from "@codemirror/state"
import { EditorView, lineNumbers } from "@codemirror/view"
import { oneDark } from "@codemirror/theme-one-dark"
import { StreamLanguage, syntaxHighlighting, HighlightStyle } from "@codemirror/language"
import { ruby } from "@codemirror/legacy-modes/mode/ruby"
import { tags as t } from "@lezer/highlight"

// =======================
// Ruby 用シンタックスハイライト設定
// =======================
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
  // =======================
  // ターゲット・値
  // =======================
  static targets = ["mount", "field"]
  static values  = { theme: String } // "light" | "dark"

  // =======================
  // ライフサイクル
  // =======================
  connect() {
    this.theme = this.themeValue === "dark" ? "dark" : "light"
    this.themeCompartment = new Compartment()

    // エディタの初期化（読み取り専用）
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

  disconnect() { this.view?.destroy() }

  // =======================
  // 外部公開メソッド
  // =======================
  // 外部からコード内容を差し替える
  set(value) {
    const text = value ?? ""
    this.fieldTarget.value = text
    if (this.view) {
      this.view.dispatch({ changes: { from: 0, to: this.view.state.doc.length, insert: text } })
    }
  }

  // =======================
  // 内部処理
  // =======================
  // コンテナ背景色をテーマに合わせて切り替え
  #applyContainerTheme() {
    const el = this.mountTarget
    el.classList.remove("bg-white", "text-slate-900", "bg-[#0b0f19]", "text-white")
    if (this.theme === "dark") {
      el.classList.add("bg-[#0b0f19]", "text-white")
    } else {
      el.classList.add("bg-white", "text-slate-900")
    }
  }
}

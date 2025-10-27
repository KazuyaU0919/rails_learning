// ============================================================
// precode_body_controller.js
// ------------------------------------------------------------
// フォームの <textarea> と連動する「編集用」CodeMirror。
// 目的：PreCode の本文編集 UI をリッチにしつつ、フォーム送信時は
//       通常の textarea に値が入るよう同期を維持。
// 特徴：
//  - フィールドの値と CodeMirror を双方向同期（エディタ → textarea）
//  - ライト/ダークテーマ切り替え（値で受け取り）
//  - Ruby 用のシンタックスハイライト適用
// ============================================================

import { Controller } from "@hotwired/stimulus"

import { EditorState, Compartment } from "@codemirror/state"
import { EditorView, lineNumbers } from "@codemirror/view"
import { oneDark } from "@codemirror/theme-one-dark"
import { StreamLanguage, syntaxHighlighting, HighlightStyle } from "@codemirror/language"
import { ruby } from "@codemirror/legacy-modes/mode/ruby"
import { tags as t } from "@lezer/highlight"

// =======================
// Ruby ハイライト定義
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
  static values  = { theme: String } // "light" or "dark"

  // =======================
  // ライフサイクル
  // =======================
  connect() {
    // 現在のテーマを決定
    this.theme = this.themeValue === "dark" ? "dark" : "light"
    this.themeCompartment = new Compartment()

    // エディタ初期化（textarea の値を初期 doc に）
    this.state = EditorState.create({
      doc: this.fieldTarget.value || "",
      extensions: [
        lineNumbers(),
        rubyLang,
        syntaxHighlighting(rubyHighlight),
        // 入力変更 → textarea に反映（フォーム送信と整合）
        EditorView.updateListener.of(v => {
          if (!v.docChanged) return
          this.fieldTarget.value = v.state.doc.toString()
        }),
        this.themeCompartment.of(this.theme === "dark" ? oneDark : []),
      ],
    })

    this.view = new EditorView({ state: this.state, parent: this.mountTarget })
    this.#applyContainerTheme()
  }

  disconnect() { this.view?.destroy() }

  // =======================
  // パブリック API
  // =======================
  // ライト/ダークの切り替え（ボタンなどから呼ぶ想定）
  toggleTheme() {
    this.theme = this.theme === "dark" ? "light" : "dark"
    this.view.dispatch({
      effects: this.themeCompartment.reconfigure(this.theme === "dark" ? oneDark : [])
    })
    this.#applyContainerTheme()
  }

  // =======================
  // 内部処理
  // =======================
  // CodeMirror を囲むコンテナの背景色/文字色をテーマに合わせる
  #applyContainerTheme() {
    const el = this.mountTarget
    el.classList.remove("bg-white","text-slate-900","bg-[#0b0f19]","text-white")
    if (this.theme === "dark") {
      el.classList.add("bg-[#0b0f19]", "text-white")
    } else {
      el.classList.add("bg-white", "text-slate-900")
    }
  }
}

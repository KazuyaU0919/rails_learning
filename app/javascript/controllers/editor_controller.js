// app/javascript/controllers/editor_controller.js
import { Controller } from "@hotwired/stimulus"
import axios from "axios"

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

const KEY = { code: "editor:code", theme: "editor:theme" }
const SAVE_DELAY = 50

export default class extends Controller {
  static targets = [
    "mount", "output", "select",
    // 問題モード（上：タイトル・問題文・ヒント）
    "quizPanelTop", "quizTitle", "quizDesc", "quizHint",
    // 問題モード（下：解答・解答コード）
    "quizPanelBottom", "quizAnswer", "quizAnswerCode"
  ]

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
    this.#applyContainerTheme()

    this.loadingCtrl = this.application.getControllerForElementAndIdentifier(this.element, "loading")

    const params = new URLSearchParams(window.location.search)
    const pid = params.get("pre_code_id")
    if (pid) this.#loadPreCodeBody(pid)
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
      this.outputTarget.textContent = (res.data.stderr && res.data.stderr.length > 0)
        ? res.data.stderr
        : res.data.stdout
    }

    try {
      if (this.loadingCtrl?.withOverlay) {
        await this.loadingCtrl.withOverlay(async (signal) => await perform(signal))
      } else {
        await perform()
      }
    } catch (e) {
      const msg = e?.response?.data?.stderr || (e?.message || e)
      this.outputTarget.textContent = `Error: ${msg}`
    } finally {
      btn?.removeAttribute("disabled")
      btn?.removeAttribute("aria-disabled")
    }
  }

  async changeSelect () {
    const id = this.hasSelectTarget ? this.selectTarget.value : ""
    if (!id) return
    await this.#loadPreCodeBody(id)
  }

  toggleTheme () {
    this.theme = this.theme === "dark" ? "light" : "dark"
    localStorage.setItem(KEY.theme, this.theme)
    this.view.dispatch({
      effects: this.themeCompartment.reconfigure(this.theme === "dark" ? oneDark : [])
    })
    this.#applyContainerTheme()
  }

  // ===== private =====
  #applyContainerTheme () {
    const el = this.mountTarget
    el.classList.remove("bg-white", "text-slate-900", "bg-[#0b0f19]", "text-white")
    if (this.theme === "dark") el.classList.add("bg-[#0b0f19]", "text-white")
    else el.classList.add("bg-white", "text-slate-900")
  }

  async #loadPreCodeBody (id) {
    try {
      const res  = await axios.get(`/pre_codes/${id}/body`)
      const data = res.data || {}

      // エディタ本文
      const body = data.body || ""
      this.view.dispatch({ changes: { from: 0, to: this.view.state.doc.length, insert: body } })
      localStorage.setItem(KEY.code, body)

      // ===== 問題モードの描画 =====
      if (data.is_quiz) {
        // 上部
        if (this.hasQuizPanelTopTarget) {
          this.quizPanelTopTarget.classList.remove("hidden")
          this.quizTitleTarget.innerHTML  = this.#safeHTML(data.title)
          this.quizDescTarget.innerHTML   = data.description_html || ""
          this.quizHintTarget.innerHTML   = data.hint_html || ""
        }
        // 下部
        if (this.hasQuizPanelBottomTarget) {
          this.quizPanelBottomTarget.classList.remove("hidden")
          this.quizAnswerTarget.innerHTML = data.answer_html || ""

          // 解答コード（code-view へ差し込み）
          if (this.quizAnswerCodeTarget) {
            // code-view コントローラを取得できれば set() で反映
            const codeView = this.application.getControllerForElementAndIdentifier(
              this.quizAnswerCodeTarget,
              "code-view"
            )
            const text = data.answer_code || ""
            if (codeView && typeof codeView.set === "function") {
              codeView.set(text)
            } else {
              // まだ接続前の場合に備え textarea にも値を入れておく
              const field = this.quizAnswerCodeTarget.querySelector("textarea")
              if (field) field.value = text
            }
          }
        }
      } else {
        // 非クイズ：パネルを隠す
        if (this.hasQuizPanelTopTarget) {
          this.quizPanelTopTarget.classList.add("hidden")
          this.quizTitleTarget.innerHTML = ""
          this.quizDescTarget.innerHTML  = ""
          this.quizHintTarget.innerHTML  = ""
        }
        if (this.hasQuizPanelBottomTarget) {
          this.quizPanelBottomTarget.classList.add("hidden")
          this.quizAnswerTarget.innerHTML = ""
          const field = this.quizAnswerCodeTarget?.querySelector("textarea")
          if (field) field.value = ""
          // code-view が接続済なら空文字に
          const codeView = this.application.getControllerForElementAndIdentifier(
            this.quizAnswerCodeTarget,
            "code-view"
          )
          if (codeView && typeof codeView.set === "function") codeView.set("")
        }
      }

      // セレクトの選択状態を同期
      if (this.hasSelectTarget) this.selectTarget.value = String(id)
    } catch (e) {
      this.outputTarget.textContent = `Load Error: ${e}`
    }
  }

  #safeHTML (text) {
    const div = document.createElement("div")
    div.textContent = text ?? ""
    return div.innerHTML
  }
}

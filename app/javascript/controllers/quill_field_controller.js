// ============================================================
// quill_field_controller.js
// ------------------------------------------------------------
// 目的：任意フォームの「表示用 div + hidden input」の組み合わせで
//       Quill を初期化し、入力結果（HTML）を hidden に同期する。
// 用途：data-controller="quill-field" の要素に対して、
//       targets: editor(表示div), input(hidden) を指定して使う。
// 特徴：
//   - Divider(<hr>) Blot を一度だけ登録
//   - 画像アップロードを ActiveStorage DirectUpload で実現
//   - 最大文字数（テキストベース）制限をオプションで提供
//     data-quill-field-max-length-value="2000" のように指定
// ============================================================

import { Controller } from "@hotwired/stimulus"
import { DirectUpload } from "@rails/activestorage"

export default class extends Controller {
  // =======================
  // ターゲット・値
  // =======================
  static targets = ["editor", "input"]
  static values  = { placeholder: String, maxLength: Number }

  // =======================
  // ライフサイクル
  // =======================
  connect() {
    if (!window.Quill || !this.hasEditorTarget || !this.hasInputTarget) return

    // ---- Divider(<hr>) を一度だけ登録 ----
    if (!window.__QL_DIVIDER_REGISTERED__) {
      const BlockEmbed = window.Quill.import("blots/block/embed")
      class Divider extends BlockEmbed {
        static blotName = "divider"
        static tagName  = "hr"
      }
      window.Quill.register(Divider, true)
      window.__QL_DIVIDER_REGISTERED__ = true
    }

    // ---- Quill 初期化 ----
    this.quill = new Quill(this.editorTarget, {
      theme: "snow",
      placeholder: this.placeholderValue || "本文を入力…",
      modules: {
        toolbar: [
          [{ header: [1,2,3,false] }],
          ["bold", "italic", "underline"],
          [{ list: "ordered" }, { list: "bullet" }],
          [{ color: [] }, { background: [] }],
          ["divider"],
          ["link", "blockquote", "code-block", "image", "clean"]
        ]
      }
    })

    // ---- ツールバー拡張 ----
    const toolbar = this.quill.getModule("toolbar")
    toolbar.addHandler("image",   () => this.handleImage())
    toolbar.addHandler("divider", () => this.handleDivider())

    // Divider ボタンの見た目を少し整える
    const btn = this.element.querySelector(".ql-toolbar button.ql-divider")
    if (btn && !btn.innerHTML.trim()) {
      btn.innerHTML = "—"
      btn.style.fontWeight = "700"
      btn.title = "横線を挿入"
    }

    // ---- 既存 HTML を流し込み（編集時）----
    if (this.inputTarget.value) {
      this.editorTarget.querySelector(".ql-editor").innerHTML = this.inputTarget.value
    }

    // ---- 入力・同期・制限 ----
    // text-change イベントで hidden に HTML を反映し、
    // 必要ならテキスト長（\n 除去後）を maxLength で制限する。
    this.quill.on("text-change", (delta, oldDelta, source) => {
      // HTML を hidden へ
      this.inputTarget.value = this.editorTarget.querySelector(".ql-editor").innerHTML

      // 文字数（改行末尾を除いたテキスト長）を制限
      if (this.hasMaxLengthValue && source === "user") {
        const textLen = this.quill.getText().replace(/\n+$/, "").length
        if (textLen > this.maxLengthValue) {
          // 超過分をざっくり戻す：末尾から (len+1) 文字削除
          const len = textLen - this.maxLengthValue
          const endIndex = this.quill.getLength()
          this.quill.deleteText(endIndex - (len + 1), len + 1, "silent")
          this.inputTarget.value = this.editorTarget.querySelector(".ql-editor").innerHTML
          this.showToast(`最大 ${this.maxLengthValue} 文字までです`)
        }
      }
    })
  }

  // =======================
  // パブリック API（ツールバーから呼ばれる）
  // =======================

  // <hr> を挿入
  handleDivider() {
    const range = this.quill.getSelection(true) || { index: this.quill.getLength() }
    this.quill.insertEmbed(range.index, "divider", true, "user")
    this.quill.setSelection(range.index + 1)
  }

  // 画像アップロード（ActiveStorage 直）
  handleImage() {
    const input = document.createElement("input")
    input.type = "file"
    input.accept = "image/*"
    input.click()

    input.onchange = () => {
      const file = input.files?.[0]
      if (!file) return

      const upload = new DirectUpload(file, "/rails/active_storage/direct_uploads")
      upload.create((error, blob) => {
        if (error) {
          this.showToast("画像アップロードに失敗しました")
          return
        }
        const url = `/rails/active_storage/blobs/redirect/${blob.signed_id}/${encodeURIComponent(file.name)}`
        const range = this.quill.getSelection(true) || { index: this.quill.getLength() }
        this.quill.insertEmbed(range.index, "image", url, "user")
        this.quill.setSelection(range.index + 1)
        // hidden 更新
        this.inputTarget.value = this.editorTarget.querySelector(".ql-editor").innerHTML
      })
    }
  }

  // =======================
  // ユーティリティ
  // =======================
  showToast(message) {
    const div = document.createElement("div")
    div.innerText = message
    div.className = "fixed bottom-4 right-4 bg-slate-800 text-white px-3 py-1.5 rounded shadow text-sm"
    document.body.appendChild(div)
    setTimeout(() => div.remove(), 1800)
  }
}

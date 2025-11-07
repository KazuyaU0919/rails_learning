// ============================================================
// quill_controller.js
// ------------------------------------------------------------
// 目的：Quill エディタ（snow）を初期化し、ActiveStorage 直接アップロードと
//       区切り線(<hr>)の挿入、色/背景色などのツールバー拡張を提供する。
// 用途：特定ページ（例：BookSection 編集）で、
//       #quill-editor の内容を #content_field(hidden) に反映して送信。
// 特徴：
//   - Divider(<hr>) の独自 Blot を一度だけ登録
//   - ツールバーの image を ActiveStorage DirectUpload に差し替え
//   - 画像幅の簡易指定（%）ダイアログ（任意）
//   - 既存 HTML を読み込んで編集継続可能
// 前提：window.Quill が読み込まれていること（UMD）
//       #quill-editor（表示側 DIV）と #content_field（hidden）が存在すること
// ============================================================

import { Controller } from "@hotwired/stimulus"
import { DirectUpload } from "@rails/activestorage"

export default class extends Controller {
  // =======================
  // ライフサイクル
  // =======================
  connect() {
    const editorEl = document.getElementById("quill-editor")
    const hiddenEl = document.getElementById("content_field")
    if (!editorEl || !hiddenEl || !window.Quill) return

    // ---- Divider(<hr>) Blot を（初回のみ）登録 ----
    if (!window.__QL_DIVIDER_REGISTERED__) {
      const BlockEmbed = window.Quill.import('blots/block/embed')
      class Divider extends BlockEmbed {
        static blotName = 'divider'
        static tagName  = 'hr'
      }
      window.Quill.register(Divider, true)
      window.__QL_DIVIDER_REGISTERED__ = true
    }

    // ---- quill-better-table の登録 ----
    // CDN で読み込んだ場合は window.QuillBetterTable に入っている
    if (window.QuillBetterTable && !window.__QL_BETTER_TABLE_REGISTERED__) {
      window.Quill.register({ 'modules/better-table': window.QuillBetterTable }, true)
      window.__QL_BETTER_TABLE_REGISTERED__ = true
    }

    // ---- Quill 初期化 ----
    this.quill = new Quill(editorEl, {
      theme: "snow",
      placeholder: "本文を入力…",
      modules: {
        toolbar: [
          [{ header: [1, 2, 3, false] }],
          ["bold", "italic", "underline"],
          [{ list: "ordered" }, { list: "bullet" }],
          [{ color: [] }, { background: [] }],
          ["divider"],
          ["link", "blockquote", "code-block", "image", "clean"],
          [{ table: "insert" }],
          ["table-insert-row", "table-insert-column", "table-delete-row", "table-delete-column", "table-merge-cells"]
        ],
        // better-table のオプション
        "better-table": {
          operationMenu: {
            items: {
              unmergeCells: { text: "セル結合を解除" }
            }
          }
        }
      }
    })

    // ---- ツールバーのボタン拡張 ----
    const toolbar = this.quill.getModule("toolbar")
    toolbar.addHandler("image",   () => this.handleImage())
    toolbar.addHandler("divider", () => this.handleDivider())

    // 表操作ハンドラ
    toolbar.addHandler("table", () => this.handleInsertTable())
    this.installTableButtons()

    // Divider ボタンを見やすく
    const dividerBtn = document.querySelector(".ql-toolbar button.ql-divider")
    if (dividerBtn && !dividerBtn.innerHTML.trim()) {
      dividerBtn.innerHTML = "—"
      dividerBtn.style.fontWeight = "700"
      dividerBtn.title = "横線を挿入"
    }

    // 既存HTMLを読み込む（編集モード）
    if (hiddenEl.value) {
      editorEl.querySelector(".ql-editor").innerHTML = hiddenEl.value
    }

    // 入力 → hidden 同期
    this.quill.on("text-change", () => {
      hiddenEl.value = editorEl.querySelector(".ql-editor").innerHTML
    })
  }

  // ========== 表ツール ==========
  installTableButtons() {
    const tb = document.querySelector(".ql-toolbar")

    const mkBtn = (cls, title, text) => {
      const b = document.createElement("button")
      b.type = "button"
      b.className = `ql-${cls}`
      b.title = title
      b.innerText = text
      tb.appendChild(b)
      b.addEventListener("click", (e) => {
        e.preventDefault()
        this.handleTableAction(cls)
      })
    }

    // ボタンをツールバーの末尾に追加（必要なら並び替えてね）
    mkBtn("table-insert-row", "行を追加", "＋行")
    mkBtn("table-insert-column", "列を追加", "＋列")
    mkBtn("table-delete-row", "行を削除", "－行")
    mkBtn("table-delete-column", "列を削除", "－列")
    mkBtn("table-merge-cells", "セル結合/解除", "結合")
  }

  handleInsertTable() {
    const mod = this.quill.getModule("better-table")
    if (!mod) return
    const rows = parseInt(prompt("行数を入力（例: 3）", "3") || "0", 10)
    const cols = parseInt(prompt("列数を入力（例: 3）", "3") || "0", 10)
    if (rows > 0 && cols > 0) mod.insertTable(rows, cols)
  }

  handleTableAction(kind) {
    const mod = this.quill.getModule("better-table")
    if (!mod) return
    switch (kind) {
      case "table-insert-row":    mod.insertRowBelow(); break
      case "table-insert-column": mod.insertColumnRight(); break
      case "table-delete-row":    mod.deleteRow(); break
      case "table-delete-column": mod.deleteColumn(); break
      case "table-merge-cells":   mod.mergeOrUnmergeCells(); break
    }
  }

  // ========== 既存のボタン ==========
  handleDivider() {
    const range = this.quill.getSelection(true) || { index: this.quill.getLength() }
    this.quill.insertEmbed(range.index, "divider", true, "user")
    this.quill.setSelection(range.index + 1)
  }

  // 画像ボタンクリック時：ActiveStorage 直アップロード → 挿入 →（任意で）サイズ指定
  handleImage() {
    // ファイル選択ダイアログを表示
    const input = document.createElement("input")
    input.type = "file"
    input.accept = "image/*"
    input.click()

    input.onchange = () => {
      const file = input.files?.[0]
      if (!file) return

      // ---- ActiveStorage 直接アップロード ----
      const upload = new DirectUpload(file, "/rails/active_storage/direct_uploads")
      upload.create((error, blob) => {
        if (error) {
          alert("画像アップロードに失敗しました")
          return
        }

        // 即時プレビュー：redirect URL を用いる
        const url = `/rails/active_storage/blobs/redirect/${blob.signed_id}/${encodeURIComponent(file.name)}`

        // 現在カーソルへ挿入
        const range = this.quill.getSelection(true) || { index: this.quill.getLength() }
        this.quill.insertEmbed(range.index, "image", url, "user")
        this.quill.setSelection(range.index + 1)

        // ---- 簡易リサイズ（% 指定） ----
        const pct = prompt("画像の幅（%）を入力（空で元サイズ）", "100")
        if (pct && /^\d{1,3}$/.test(pct)) {
          // 直近で挿入した画像を query して style を当てる
          const esc = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
          const img = this.quill.root.querySelector(`img[src="${esc(url)}"]`)
          if (img) { img.style.width = `${pct}%`; img.style.height = "auto" }
        }

        // hidden に現在の HTML を保存（フォーム送信で DB へ）
        const editorEl = document.getElementById("quill-editor")
        const hiddenEl = document.getElementById("content_field")
        hiddenEl.value = editorEl.querySelector(".ql-editor").innerHTML
      })
    }
  }
}

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

    // ---- Quill 初期化 ----
    this.quill = new Quill(editorEl, {
      theme: "snow",
      placeholder: "本文を入力…",
      modules: {
        toolbar: [
          [{ header: [1, 2, 3, false] }],
          ["bold", "italic", "underline"],
          [{ list: "ordered" }, { list: "bullet" }],
          // 色 & 背景色
          [{ color: [] }, { background: [] }],
          // 区切り線（フル幅）
          ["divider"],
          ["link", "blockquote", "code-block", "image", "clean"]
        ]
      }
    })

    // ---- ツールバーのボタン拡張 ----
    const toolbar = this.quill.getModule("toolbar")
    toolbar.addHandler("image",   () => this.handleImage())
    toolbar.addHandler("divider", () => this.handleDivider())

    // Divider ボタンを目立つ記号に（最初の初期化時のみ空のはず）
    const dividerBtn = document.querySelector(".ql-toolbar button.ql-divider")
    if (dividerBtn && !dividerBtn.innerHTML.trim()) {
      dividerBtn.innerHTML = "—"
      dividerBtn.style.fontWeight = "700"
      dividerBtn.title = "横線を挿入"
    }

    // ---- 既存 HTML を読み込む（編集モード時） ----
    if (hiddenEl.value) {
      editorEl.querySelector(".ql-editor").innerHTML = hiddenEl.value
    }

    // ---- 入力 → hidden 同期 ----
    this.quill.on("text-change", () => {
      hiddenEl.value = editorEl.querySelector(".ql-editor").innerHTML
    })
  }

  // =======================
  // パブリック API（ツールバーから呼ばれる）
  // =======================

  // 区切り線（<hr>）を現在カーソル位置に挿入
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
          if (img) {
            img.style.width = `${pct}%`
            img.style.height = "auto"
          }
        }

        // hidden に現在の HTML を保存（フォーム送信で DB へ）
        const editorEl = document.getElementById("quill-editor")
        const hiddenEl = document.getElementById("content_field")
        hiddenEl.value = editorEl.querySelector(".ql-editor").innerHTML
      })
    }
  }
}

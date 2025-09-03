// app/javascript/controllers/quill_controller.js
import { Controller } from "@hotwired/stimulus"
import { DirectUpload } from "@rails/activestorage"

// Stimulus controller: Quill + ActiveStorage DirectUpload (image button override + divider/color/bg)
export default class extends Controller {
  connect() {
    const editorEl = document.getElementById("quill-editor")
    const hiddenEl = document.getElementById("content_field")
    if (!editorEl || !hiddenEl || !window.Quill) return

    // --- カスタム <hr> Blot 登録（初回のみ） ---
    if (!window.__QL_DIVIDER_REGISTERED__) {
      const BlockEmbed = window.Quill.import('blots/block/embed')
      class Divider extends BlockEmbed {
        static blotName = 'divider'
        static tagName  = 'hr'
      }
      window.Quill.register(Divider, true)
      window.__QL_DIVIDER_REGISTERED__ = true
    }

    // Quill 初期化
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

    // Quill のツールバーから image 押下時の動作を上書き
    const toolbar = this.quill.getModule("toolbar")
    toolbar.addHandler("image", () => this.handleImage())
    toolbar.addHandler("divider", () => this.handleDivider())

    // （既にある）toolbar 取得の直後に追加
    const dividerBtn = document.querySelector(".ql-toolbar button.ql-divider");
    if (dividerBtn && !dividerBtn.innerHTML.trim()) {
      dividerBtn.innerHTML = "—";
      dividerBtn.style.fontWeight = "700";
      dividerBtn.title = "横線を挿入";
    }

    // 既存 HTML を流し込む（編集時）
    if (hiddenEl.value) {
      editorEl.querySelector(".ql-editor").innerHTML = hiddenEl.value
    }

    // 入力 → hidden 同期
    this.quill.on("text-change", () => {
      hiddenEl.value = editorEl.querySelector(".ql-editor").innerHTML
    })
  }

  // 区切り線（<hr>）の挿入
  handleDivider() {
    const range = this.quill.getSelection(true) || { index: this.quill.getLength() }
    this.quill.insertEmbed(range.index, "divider", true, "user")
    this.quill.setSelection(range.index + 1)
  }

  // 画像ボタンクリック時の処理
  handleImage() {
    // ファイル選択ダイアログを出す
    const input = document.createElement("input")
    input.type = "file"
    input.accept = "image/*"
    input.click()

    input.onchange = () => {
      const file = input.files?.[0]
      if (!file) return

      // ActiveStorage へ直接アップロード
      const upload = new DirectUpload(file, "/rails/active_storage/direct_uploads")
      upload.create((error, blob) => {
        if (error) {
          alert("画像アップロードに失敗しました")
          return
        }

        // 即時プレビューは blob の redirect URL を使えばOK
        // 例) /rails/active_storage/blobs/redirect/:signed_id/:filename
        const url = `/rails/active_storage/blobs/redirect/${blob.signed_id}/${encodeURIComponent(file.name)}`

        // カーソル位置へ <img> を挿入
        const range = this.quill.getSelection(true) || { index: this.quill.getLength() }
        this.quill.insertEmbed(range.index, "image", url, "user")
        this.quill.setSelection(range.index + 1)

        // --- 簡易リサイズ（% 指定） ----------
        const pct = prompt("画像の幅（%）を入力（空で元サイズ）", "100")
        if (pct && /^\d{1,3}$/.test(pct)) {
          // 直近で挿入した画像を探して width を付与
          const esc = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
          const img = this.quill.root.querySelector(`img[src="${esc(url)}"]`)
          if (img) {
            img.style.width = `${pct}%`
            img.style.height = "auto"
          }
        }

        // hidden にも現在のHTMLを保存（フォーム送信時にDBへ入る）
        const editorEl = document.getElementById("quill-editor")
        const hiddenEl = document.getElementById("content_field")
        hiddenEl.value = editorEl.querySelector(".ql-editor").innerHTML
      })
    }
  }
}

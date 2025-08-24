import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    const editorEl = document.getElementById("quill-editor")
    const hiddenEl = document.getElementById("content_field")
    if (!editorEl || !hiddenEl || !window.Quill) return

    this.quill = new Quill(editorEl, {
      theme: "snow",
      placeholder: "本文を入力…",
      modules: {
        toolbar: [
          [{ header: [1, 2, 3, false] }],
          ["bold", "italic", "underline", "code"],
          [{ list: "ordered" }, { list: "bullet" }],
          ["link", "blockquote", "code-block", "clean"]
        ]
      }
    })

    // 編集時に既存HTMLを流し込む
    if (hiddenEl.value) editorEl.querySelector(".ql-editor").innerHTML = hiddenEl.value

    // 内容を hidden に同期
    this.quill.on("text-change", () => {
      hiddenEl.value = editorEl.querySelector(".ql-editor").innerHTML
    })
  }
}

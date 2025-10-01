// app/javascript/controllers/share_controller.js
import { Controller } from "@hotwired/stimulus"

// data-controller="share" data-share-url-value="..." を想定
export default class extends Controller {
  static values = { url: String }

  copy(event) {
    event.preventDefault()
    navigator.clipboard.writeText(this.urlValue).then(() => {
      this.showToast("リンクをコピーしました ✅")
    }).catch(() => {
      this.showToast("コピーに失敗しました ❌")
    })
  }

  openTwitter(event) {
    event.preventDefault()
    const text = event.target.dataset.text || ""
    const shareUrl = `https://twitter.com/intent/tweet?text=${encodeURIComponent(text)}&url=${encodeURIComponent(this.urlValue)}`
    window.open(shareUrl, "_blank", "noopener,noreferrer") ||
      this.showToast("Xを開けませんでした。ブラウザの設定をご確認ください")
  }

  showToast(message) {
    // ここは簡易実装。既存のToastライブラリがあるならそちらを呼ぶ
    const div = document.createElement("div")
    div.innerText = message
    div.className = "fixed bottom-4 right-4 bg-slate-800 text-white px-4 py-2 rounded shadow"
    document.body.appendChild(div)
    setTimeout(() => div.remove(), 2500)
  }
}

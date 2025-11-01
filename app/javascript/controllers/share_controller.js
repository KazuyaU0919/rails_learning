// ============================================================
// share_controller.js
// ------------------------------------------------------------
// 目的：Rails Learning で「共有」操作（URLコピー・X(Twitter)共有）を行う。
// 用途：data-controller="share" data-share-url-value="..." を指定して利用。
// 特徴：
//   - navigator.clipboard でクリップボードコピー
//   - Twitter共有（intent/tweet）を新しいタブで開く
//   - 成功/失敗時に簡易トーストを表示
// ============================================================

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  // =======================
  // 値（Stimulus Values）
  // =======================
  static values = { url: String }

  // =======================
  // イベントハンドラ：リンクコピー
  // =======================
  copy(event) {
    event.preventDefault()
    navigator.clipboard.writeText(this.urlValue)
      .then(() => this.showToast("リンクをコピーしました ✅"))
      .catch(() => this.showToast("コピーに失敗しました ❌"))
  }

  // =======================
  // イベントハンドラ：X（旧Twitter）共有
  // =======================
  openTwitter(event) {
    event.preventDefault()
    const text = event.target.dataset.text || ""
    const shareUrl = `https://twitter.com/intent/tweet?text=${encodeURIComponent(text)}&url=${encodeURIComponent(this.urlValue)}`

    // ポップアップで開けない場合、警告表示
    window.open(shareUrl, "_blank", "noopener,noreferrer") ||
      this.showToast("Xを開けませんでした。ブラウザの設定をご確認ください")
  }

  // =======================
  // トースト（簡易通知）
  // =======================
  showToast(message) {
    const div = document.createElement("div")
    div.innerText = message
    div.className = "fixed bottom-4 right-4 bg-slate-800 text-white px-4 py-2 rounded shadow"
    document.body.appendChild(div)
    setTimeout(() => div.remove(), 2500)
  }
}

// ============================================================
// tag_token_controller.js
// ------------------------------------------------------------
// 目的：タグ入力欄で、ユーザー入力に応じたタグ候補を提示する。
// 用途：
//   data-controller="tag-token" を input に付与し、
//   下部に id="tag-suggest" の要素を配置する。
// 特徴：
//   - 入力値を , 区切りで分割し、末尾の単語からタグ候補を取得
//   - fetch(`/tags.json?query=...`) により候補リストを取得して表示
// ============================================================

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  // =======================
  // イベント: 入力補完
  // =======================
  suggest(e) {
    const q = e.target.value.split(",").pop().trim()
    if (!q) return

    fetch(`/tags.json?query=${encodeURIComponent(q)}`)
      .then(r => r.json())
      .then(list => {
        const names = list.slice(0, 6).map(t => t.name).join(", ")
        document.getElementById("tag-suggest").textContent =
          names ? `候補: ${names}` : ""
      })
  }
}

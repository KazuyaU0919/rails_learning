// ============================================================
// code_highlight_controller.js
// ------------------------------------------------------------
// 静的に描画済みのコードブロックに対して、highlight.js を用いて
// シンタックスハイライトを適用するコントローラ。
// 特色：
// - UMD で読み込まれた window.hljs に依存（遅延ロード想定）
// - Quill の <pre class="ql-syntax"> のように <code> を内包しない要素も
//   自動で <code> でラップした上でハイライトを適用
// - 最大 ~2 秒（50ms × 40回）までポーリングして hljs の準備完了を待つ
// ============================================================

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  // =======================
  // ライフサイクル
  // =======================
  connect() {
    // highlight.js がまだ読み込まれていない場合に備えてポーリング開始
    this._tryHighlight(0)
  }

  // =======================
  // 内部処理
  // =======================

  /**
   * highlight.js のロード完了をリトライしながら待ち、
   * 準備でき次第ハイライトを実行する。
   * @param {number} retry 現在のリトライ回数
   */
  _tryHighlight(retry) {
    const hljs = window.hljs
    if (!hljs || !hljs.highlightElement) {
      // 50ms 間隔で最大 40 回（約 2 秒）待機
      if (retry < 40) setTimeout(() => this._tryHighlight(retry + 1), 50)
      return
    }
    this._highlightAll(hljs)
  }

  /**
   * 対象要素内の pre を走査し、<code> が無いものを自動でラップしてから
   * すべての <pre><code> にハイライトを適用する。
   * @param {object} hljs window.hljs
   */
  _highlightAll(hljs) {
    // 1) <code> を含まない pre を先に <code> で包む
    //    - Quill の <pre class="ql-syntax"> などにも対応
    const pres = this.element.querySelectorAll(".content-body pre, pre")
    pres.forEach(pre => {
      if (!pre.querySelector("code")) {
        const code = document.createElement("code")
        // HTMLではなくテキストとして移す（XSS上も安全）
        code.textContent = pre.textContent
        pre.textContent = ""
        pre.appendChild(code)
      }
    })

    // 2) すべての <pre><code> をハイライト
    const blocks = this.element.querySelectorAll("pre code, .content-body pre code")
    blocks.forEach(el => {
      if (!el.classList.contains("hljs")) {
        try { hljs.highlightElement(el) } catch (_) { /* 1つ失敗しても続行 */ }
      }
    })
  }
}

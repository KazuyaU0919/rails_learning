// app/javascript/controllers/code_highlight_controller.js
import { Controller } from "@hotwired/stimulus"

/**
 * - window.hljs（UMD）を利用
 * - Quill の <pre class="ql-syntax"> など、<code> を内包しないブロックも
 *   自動で <code> ラップしてからハイライト
 */
export default class extends Controller {
  connect () {
    // hljs がまだ読み込まれていない場合に備えてポーリング
    this._tryHighlight(0)
  }

  _tryHighlight (retry) {
    const hljs = window.hljs
    if (!hljs || !hljs.highlightElement) {
      if (retry < 40) { // 最大 ~2秒（50ms * 40）
        setTimeout(() => this._tryHighlight(retry + 1), 50)
      }
      return
    }
    this._highlightAll(hljs)
  }

  _highlightAll (hljs) {
    // 1) Quill の <pre class="ql-syntax"> など、<code> を含まない pre を先に <code> で包む
    const pres = this.element.querySelectorAll(".content-body pre, pre")
    pres.forEach(pre => {
      if (!pre.querySelector("code")) {
        const code = document.createElement("code")
        // pre のテキストを code に移す（HTML を解釈しない）
        code.textContent = pre.textContent
        // 既存内容クリアして code を追加
        pre.textContent = ""
        pre.appendChild(code)
      }
    })

    // 2) すべての <pre><code> をハイライト
    const blocks = this.element.querySelectorAll("pre code, .content-body pre code")
    blocks.forEach(el => {
      if (!el.classList.contains("hljs")) {
        try { hljs.highlightElement(el) } catch (_) {}
      }
    })
  }
}

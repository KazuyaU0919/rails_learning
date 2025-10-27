// ============================================================
// application.js
// ------------------------------------------------------------
// Stimulus アプリケーションのエントリポイント。
// 各コントローラを登録・起動する。
// ============================================================

import { Application } from "@hotwired/stimulus"

const application = Application.start()

// =======================
// 開発時の設定
// =======================
application.debug = false
window.Stimulus   = application

export { application }

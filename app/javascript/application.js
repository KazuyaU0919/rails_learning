// ============================================================
// application.js
// ------------------------------------------------------------
// 目的：Rails Learning 全体の JavaScript 初期化。
// 機能：
//   - Turbo, Stimulus, ActiveStorage のセットアップ
//   - axios の共通設定（CSRF対策・JSON通信）
// ============================================================

import "@hotwired/turbo-rails"

// =======================
// Active Storage 設定
// =======================
import * as ActiveStorage from "@rails/activestorage"
ActiveStorage.start()

// =======================
// Stimulus Controllers
// =======================
import "controllers"

// =======================
// axios 設定
// =======================
import axios from "axios"

// ------------------------------------------------------------
// CSRF対策：Rails が meta タグで出力するトークンを axios に反映
// ------------------------------------------------------------
const token = document.querySelector('meta[name="csrf-token"]')?.getAttribute("content")
if (token) {
  axios.defaults.headers.common["X-CSRF-Token"] = token
}

// ------------------------------------------------------------
// Rails 互換ヘッダ & JSON通信設定
// ------------------------------------------------------------
axios.defaults.headers.common["X-Requested-With"] = "XMLHttpRequest"
axios.defaults.headers.common["Content-Type"] = "application/json"
axios.defaults.headers.common["Accept"] = "application/json"

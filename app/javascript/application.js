// app/javascript/application.js

import "@hotwired/turbo-rails"

// Active Storage（DirectUpload 等を有効化）
import * as ActiveStorage from "@rails/activestorage"
ActiveStorage.start()

import "controllers"

// HTTP 通信ライブラリ axios を利用
import axios from "axios"

// ===============================
// CSRF対策 & JSONリクエスト設定
// ===============================

// Railsが出力するCSRFトークンを <meta> タグから取得
const token = document.querySelector('meta[name="csrf-token"]')?.getAttribute("content")

// CSRFトークンが存在する場合、axiosの共通ヘッダに追加
if (token) {
  axios.defaults.headers.common["X-CSRF-Token"] = token
}

// Railsが期待するリクエスト種別を明示
axios.defaults.headers.common["X-Requested-With"] = "XMLHttpRequest"

// JSON形式で送受信することを明示
axios.defaults.headers.common["Content-Type"] = "application/json"
axios.defaults.headers.common["Accept"] = "application/json"

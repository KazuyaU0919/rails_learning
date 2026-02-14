# config/importmap.rb

# ================================
# 基本アプリ (エントリポイント)
# ================================
pin "application"

# ================================
# Rails 公式ライブラリ
# ================================
pin "@hotwired/turbo-rails",    to: "turbo.min.js"
pin "@hotwired/stimulus",       to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin "@rails/activestorage",     to: "@rails--activestorage.js" # ActiveStorage DirectUpload 用

# Stimulus コントローラーを一括で読み込み
pin_all_from "app/javascript/controllers", under: "controllers"

# ================================
# 外部ライブラリ
# ================================

# axios (HTTP 通信ライブラリ)
pin "axios", to: "https://cdn.jsdelivr.net/npm/axios@1.13.5/+esm"

# ================================
# CodeMirror 6 minimal set
# ================================

# 状態管理
pin "@codemirror/state",    to: "https://esm.sh/@codemirror/state@6"
# エディタビュー (本体 UI)
pin "@codemirror/view",     to: "https://esm.sh/@codemirror/view@6"
# 言語拡張 (高ライト/言語基盤)
pin "@codemirror/language", to: "https://esm.sh/@codemirror/language@6"
# JavaScript サポート
pin "@codemirror/lang-javascript", to: "https://esm.sh/@codemirror/lang-javascript@6"
# CM5 legacy Ruby mode
pin "@codemirror/legacy-modes/mode/ruby",
    to: "https://cdn.jsdelivr.net/npm/@codemirror/legacy-modes@6.3.3/mode/ruby.js"

# ================================
# その他
# ================================

# ダークテーマ
pin "@codemirror/theme-one-dark", to: "https://esm.sh/@codemirror/theme-one-dark@6"
# ハイライト (tags / HighlightStyle の提供元)
pin "@lezer/highlight", to: "https://esm.sh/@lezer/highlight@1/es2022/highlight.mjs"

// ============================================================
// controllers/index.js
// ------------------------------------------------------------
// Stimulus コントローラのエントリポイント。
// - application を初期化した controllers/application から取得
// - controllers ディレクトリ配下の *_controller を「eager」登録
//   することで importmap 環境でも自動読込を実現
// ============================================================

import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"

// =======================
// コントローラ一括登録
// =======================
// ここで controllers ディレクトリ配下を探索してすべて登録。
// Vite 等のバンドラ不要でシンプルに運用できる。
eagerLoadControllersFrom("controllers", application)

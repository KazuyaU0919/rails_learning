// ============================================================
// Stimulus: quiz-form
// ------------------------------------------------------------
// Quiz の選択に応じて QuizSection のプルダウンを絞り込む。
// ルーティング: GET /admin/quiz_sections/options?quiz_id=:id
// 返却JSON: [{ id: number, text: string }, ...]
// ============================================================

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["quiz", "section"]

  connect() {
    // 画面初期表示時にも Quiz に紐づく Section だけを表示
    this.onQuizChange()
  }

  async onQuizChange() {
    const quizId = this.quizTarget.value
    if (!quizId) return

    try {
      const res = await fetch(`/admin/quiz_sections/options?quiz_id=${encodeURIComponent(quizId)}`, {
        headers: { "Accept": "application/json" },
        credentials: "same-origin"
      })
      if (!res.ok) throw new Error(`HTTP ${res.status}`)
      const items = await res.json() // [{id, text}]
      this.replaceSectionOptions(items)
    } catch (e) {
      console.error("[quiz-form] failed to load sections:", e)
    }
  }

  replaceSectionOptions(items) {
    const current = this.sectionTarget.value
    this.sectionTarget.innerHTML = ""

    items.forEach(({ id, text }) => {
      const opt = document.createElement("option")
      opt.value = String(id)
      opt.textContent = text
      this.sectionTarget.appendChild(opt)
    })

    // 既存値が同一 Quiz 内にあれば選択を維持
    if (current && Array.from(this.sectionTarget.options).some(o => o.value === current)) {
      this.sectionTarget.value = current
    }
  }
}

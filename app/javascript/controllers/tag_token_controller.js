// app/javascript/controllers/tag_token_controller.js
import { Controller } from "@hotwired/stimulus"
export default class extends Controller {
  suggest(e) {
    const q = e.target.value.split(",").pop().trim()
    if (!q) return
    fetch(`/tags.json?query=${encodeURIComponent(q)}`)
      .then(r => r.json())
      .then(list => {
        const names = list.slice(0, 6).map(t => t.name).join(", ")
        document.getElementById("tag-suggest").textContent = names ? `候補: ${names}` : ""
      })
  }
}

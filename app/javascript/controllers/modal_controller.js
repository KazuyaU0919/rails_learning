// app/javascript/controllers/modal_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "panel", "backdrop"]

  connect() {
    this._onKeydown = (e) => { if (e.key === "Escape") this.close() }
  }

  open() {
    this.containerTarget.classList.remove("hidden")
    document.body.classList.add("overflow-hidden")
    document.addEventListener("keydown", this._onKeydown)

    const f = this.panelTarget.querySelector("[data-autofocus]") ||
              this.panelTarget.querySelector("a,button,input,select,textarea,[tabindex]:not([tabindex='-1'])")
    if (f) f.focus()
  }

  close() {
    this.containerTarget.classList.add("hidden")
    document.body.classList.remove("overflow-hidden")
    document.removeEventListener("keydown", this._onKeydown)
  }

  backdrop(e) { if (e.target === this.backdropTarget) this.close() }
}

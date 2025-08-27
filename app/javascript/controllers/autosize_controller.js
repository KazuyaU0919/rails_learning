import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["field", "counter"]; // ← 追加：textarea とカウンタ
  static values = {
    minRows: Number,
    maxLength: Number,
  };

  connect() {
    this.grow();
    this.updateCounter();
    this.fieldTarget.addEventListener("input", () => {
      this.grow();
      this.updateCounter();
    });
  }

  grow() {
    const ta = this.fieldTarget; // ← textarea を明示
    const baseRows = this.hasMinRowsValue ? this.minRowsValue : (parseInt(ta.getAttribute("rows")) || 2);
    ta.rows = baseRows;

    const lineHeight = parseInt(getComputedStyle(ta).lineHeight || "20", 10);
    const newRows = Math.ceil((ta.scrollHeight - ta.clientTop - ta.clientTop) / lineHeight);
    ta.rows = Math.max(baseRows, newRows);
  }

  updateCounter() {
    if (!this.hasMaxLengthValue || this.counterTargets.length === 0) return;
    const remain = Math.max(0, this.maxLengthValue - this.fieldTarget.value.length);
    this.counterTargets.forEach(el => (el.textContent = remain));
  }
}

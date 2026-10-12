import { Controller } from "@hotwired/stimulus"

// Job detail: ask for a reason before marking a scheduled job on hold.
export default class extends Controller {
  static targets = [ "dialog", "reason" ]
  static values = { open: { type: Boolean, default: false } }

  connect() {
    this.onKeydown = this.onKeydown.bind(this)
    if (this.openValue) this.show()
  }

  disconnect() {
    this.unlock()
    document.removeEventListener("keydown", this.onKeydown)
  }

  show(event) {
    if (event) event.preventDefault()
    if (!this.hasDialogTarget) return

    this.dialogTarget.hidden = false
    document.documentElement.classList.add("planner-modal-open")
    document.addEventListener("keydown", this.onKeydown)
    if (this.hasReasonTarget) this.reasonTarget.focus()
  }

  hide(event) {
    if (event) event.preventDefault()
    if (this.hasDialogTarget) this.dialogTarget.hidden = true
    this.unlock()
    document.removeEventListener("keydown", this.onKeydown)
  }

  backdropClose(event) {
    if (event.target === event.currentTarget) this.hide(event)
  }

  onKeydown(event) {
    if (event.key === "Escape") this.hide(event)
  }

  unlock() {
    document.documentElement.classList.remove("planner-modal-open")
  }
}
